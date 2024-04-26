{-
  Copyright (c) Meta Platforms, Inc. and affiliates.
  All rights reserved.

  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree.
-}

-- | Higher level concurrency facilities for multiple workers concurrently
-- over a streaming source of input

module Control.Concurrent.Stream
  ( stream
  , streamBound
  , streamWithState
  , streamWithResourceBound
  , mapConcurrently_unordered
  , forConcurrently_unordered
  ) where

import Control.Concurrent.Async
import Control.Concurrent.STM
import Control.Exception
import Control.Monad

import Util.Control.Exception
import Util.Log
import Data.IORef
import Data.IORef.Extra

data ShouldBindThreads = BoundThreads | UnboundThreads

data ShouldThrow = ThrowExceptions | SwallowExceptions

-- | Maps workers concurrently over a stream of values with a bounded size
--
-- Runs the producer until it terminates, passing in a function to add things
-- into the stream. Runs at most `maxConcurrency` threads simultaneously to
-- process things put into the stream.
-- There's no end aggregation for the output from each worker, which doesn't
-- make this composable. We can add that in the future when needed.
--
-- If a worker throws a synchronous exception, it will be
-- propagated to the caller.
--
-- `conduit` and `pipes` provide functionality for running consecutive stages
-- in parallel, but nothing for running a single stage concurrently.
stream
  :: Int -- ^ Maximum Concurrency
  -> ((a -> IO ()) -> IO ()) -- ^ Producer
  -> (a -> IO ()) -- ^ Worker
  -> IO ()
stream maxConcurrency producer worker =
  streamWithState producer (replicate maxConcurrency ()) $ const worker

-- | Like stream, but uses bound threads for the workers.  See
-- 'Control.Concurrent.forkOS' for details on bound threads.
streamBound
  :: Int -- ^ Maximum Concurrency
  -> ((a -> IO ()) -> IO ()) -- ^ Producer
  -> (a -> IO ()) -- ^ Worker
  -> IO ()
streamBound maxConcurrency producer worker =
  streamWithResourceBound maxConcurrency ($ ()) producer $ const worker

-- | Like stream, but each worker keeps a state: the state can be a parameter
-- to the worker function, or a state that you can build upon (for example the
-- state can be an IORef of some sort)
-- There will be a thread per worker state
streamWithState
  :: ((a -> IO ()) -> IO ()) -- ^ Producer
  -> [b] -- ^ Worker state
  -> (b -> a -> IO ()) -- ^ Worker
  -> IO ()
streamWithState producer states worker = stream_ UnboundThreads ThrowExceptions
  ($ ()) producer states (const worker)

-- | Like streamWithState but uses bound threads for the workers.
streamWithResourceBound
  :: Int  -- ^ Maximum concurrency
  -> ((resource -> IO ()) -> IO ()) -- ^ Worker resource acquisition, per thread
  -> ((a -> IO ()) -> IO ()) -- ^ Producer
  -> (resource -> a -> IO ()) -- ^ Worker
  -> IO ()
streamWithResourceBound maxConcurrency withResource producer worker =
  stream_ BoundThreads ThrowExceptions
    withResource producer (replicate maxConcurrency ()) (\r _ -> worker r)

stream_
  :: ShouldBindThreads -- use bound threads?
  -> ShouldThrow -- propagate worker exceptions?
  -> ((resource -> IO ()) -> IO ()) -- ^ resource acquisition
  -> ((a -> IO ()) -> IO ()) -- ^ Producer
  -> [b] -- Worker state
  -> (resource -> b -> a -> IO ()) -- ^ Worker
  -> IO ()
stream_ useBoundThreads shouldThrow withResource producer workerStates worker
  = do
  let maxConcurrency = length workerStates
  q <- atomically $ newTBQueue (fromIntegral maxConcurrency)
  let write x = atomically $ writeTBQueue q (Just x)
  mask $ \unmask ->
    concurrently_ (runWorkers unmask q) $ unmask $ do
      -- run the producer
      producer write
      -- write end-markers for all workers
      replicateM_ maxConcurrency $
        atomically $ writeTBQueue q Nothing
  where
    runWorkers unmask q = case useBoundThreads of
      BoundThreads ->
        foldr1 concurrentlyBound $
          map (withResource . runWorker unmask q) workerStates
      UnboundThreads ->
        mapConcurrently_ (withResource . runWorker unmask q) workerStates

    concurrentlyBound l r =
      withAsyncBound l $ \a ->
      withAsyncBound r $ \b ->
      void $ waitBoth a b

    runWorker unmask q s resource = do
      v <- atomically $ readTBQueue q
      case v of
        Nothing -> return ()
        Just t -> do
          e <- tryAll $ unmask $ worker resource s t
          case e of
            Left ex -> case shouldThrow of
              ThrowExceptions -> throw ex
              SwallowExceptions -> logError $ show ex
            Right _ -> return ()
          runWorker unmask q s resource

-- | Concurrent map over a stream of values. Results are unordered.
--
-- Convenience interface over Control.Concurrent.Stream (stream),
-- for processing values in lists in the same manner as mapConcurrently.
-- The list of output values may not be in the same order as the list
-- of input values.
mapConcurrently_unordered
  :: Int -- ^ Maximum concurrency
  -> (a -> IO b) -- ^ Function to map over the input values
  -> [a] -- ^ List of input values
  -> IO [b] -- ^ List of output values (unordered)
mapConcurrently_unordered maxConcurrency transformIO input = do
  outputRef <- Data.IORef.newIORef []
  stream maxConcurrency (forM_ input) $ \inputElement -> do
    transformedElement <- transformIO inputElement
    Data.IORef.Extra.atomicModifyIORef_ outputRef (transformedElement:)
  Data.IORef.readIORef outputRef

-- | Control.Concurrent.Stream (mapConcurrently) but with its arguments reversed
--
-- The list of output values may not be in the same order as the list
-- of input values.
forConcurrently_unordered
  :: Int -- ^ Maximum concurrency
  -> [a] -- ^ List of input values
  -> (a -> IO b) -- ^ Function to map over the input values
  -> IO [b] -- ^ List of output values (unordered)
forConcurrently_unordered = flip . mapConcurrently_unordered
