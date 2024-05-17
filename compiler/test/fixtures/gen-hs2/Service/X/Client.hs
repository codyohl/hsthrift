-----------------------------------------------------------------
-- Autogenerated by Thrift
--
-- DO NOT EDIT UNLESS YOU ARE SURE THAT YOU KNOW WHAT YOU ARE DOING
--  @generated
-----------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE BangPatterns #-}
{-# OPTIONS_GHC -fno-warn-unused-imports#-}
{-# OPTIONS_GHC -fno-warn-overlapping-patterns#-}
{-# OPTIONS_GHC -fno-warn-incomplete-patterns#-}
{-# OPTIONS_GHC -fno-warn-incomplete-uni-patterns#-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}
module Service.X.Client
       (X, testFunc, testFuncIO, send_testFunc, _build_testFunc,
        recv_testFunc, _parse_testFunc)
       where
import qualified Control.Arrow as Arrow
import qualified Control.Concurrent as Concurrent
import qualified Control.Exception as Exception
import qualified Control.Monad as Monad
import qualified Control.Monad.Trans.Class as Trans
import qualified Control.Monad.Trans.Reader as Reader
import qualified Data.ByteString.Builder as ByteString
import qualified Data.ByteString.Lazy as LBS
import qualified Data.HashMap.Strict as HashMap
import qualified Data.Int as Int
import qualified Data.List as List
import qualified Data.Proxy as Proxy
import qualified Prelude as Prelude
import qualified Thrift.Binary.Parser as Parser
import qualified Thrift.Codegen as Thrift
import qualified Thrift.Protocol.ApplicationException.Types
       as Thrift
import qualified Thrift.Types as Thrift
import Data.Monoid ((<>))
import Prelude ((==), (=<<), (>>=), (<$>), (.))
import Service.Types

data X

testFunc ::
           (Thrift.Protocol p, Thrift.ClientChannel c, (Thrift.<:) s X) =>
           Thrift.ThriftM p c s Int.Int32
testFunc
  = do Thrift.ThriftEnv _proxy _channel _opts _counter <- Reader.ask
       Trans.lift (testFuncIO _proxy _channel _counter _opts)

testFuncIO ::
             (Thrift.Protocol p, Thrift.ClientChannel c, (Thrift.<:) s X) =>
             Proxy.Proxy p ->
               c s -> Thrift.Counter -> Thrift.RpcOptions -> Prelude.IO Int.Int32
testFuncIO _proxy _channel _counter _opts
  = do (_handle, _sendCob, _recvCob) <- Thrift.mkCallbacks
                                          (recv_testFunc _proxy)
       send_testFunc _proxy _channel _counter _sendCob _recvCob _opts
       Thrift.wait _handle

send_testFunc ::
                (Thrift.Protocol p, Thrift.ClientChannel c, (Thrift.<:) s X) =>
                Proxy.Proxy p ->
                  c s ->
                    Thrift.Counter ->
                      Thrift.SendCallback ->
                        Thrift.RecvCallback -> Thrift.RpcOptions -> Prelude.IO ()
send_testFunc _proxy _channel _counter _sendCob _recvCob _rpcOpts
  = do _seqNum <- _counter
       let
         _callMsg
           = LBS.toStrict
               (ByteString.toLazyByteString (_build_testFunc _proxy _seqNum))
       Thrift.sendRequest _channel
         (Thrift.Request _callMsg
            (Thrift.setRpcPriority _rpcOpts Thrift.NormalPriority))
         _sendCob
         _recvCob

recv_testFunc ::
                (Thrift.Protocol p) =>
                Proxy.Proxy p ->
                  Thrift.Response -> Prelude.Either Exception.SomeException Int.Int32
recv_testFunc _proxy (Thrift.Response _response _)
  = Monad.join
      (Arrow.left (Exception.SomeException . Thrift.ProtocolException)
         (Parser.parse (_parse_testFunc _proxy) _response))

_build_testFunc ::
                  Thrift.Protocol p =>
                  Proxy.Proxy p -> Int.Int32 -> ByteString.Builder
_build_testFunc _proxy _seqNum
  = Thrift.genMsgBegin _proxy "testFunc" 1 _seqNum <>
      Thrift.genStruct _proxy []
      <> Thrift.genMsgEnd _proxy

_parse_testFunc ::
                  Thrift.Protocol p =>
                  Proxy.Proxy p ->
                    Parser.Parser (Prelude.Either Exception.SomeException Int.Int32)
_parse_testFunc _proxy
  = do Thrift.MsgBegin _name _msgTy _ <- Thrift.parseMsgBegin _proxy
       _result <- case _msgTy of
                    1 -> Prelude.fail "testFunc: expected reply but got function call"
                    2 | _name == "testFunc" ->
                        do let
                             _idMap = HashMap.fromList [("testFunc_success", 0)]
                           _fieldBegin <- Thrift.parseFieldBegin _proxy 0 _idMap
                           case _fieldBegin of
                             Thrift.FieldBegin _type _id _bool -> do case _id of
                                                                       0 | _type ==
                                                                             Thrift.getI32Type
                                                                               _proxy
                                                                           ->
                                                                           Prelude.fmap
                                                                             Prelude.Right
                                                                             (Thrift.parseI32
                                                                                _proxy)
                                                                       _ -> Prelude.fail
                                                                              (Prelude.unwords
                                                                                 ["unrecognized exception, type:",
                                                                                  Prelude.show
                                                                                    _type,
                                                                                  "field id:",
                                                                                  Prelude.show _id])
                             Thrift.FieldEnd -> Prelude.fail "no response"
                      | Prelude.otherwise -> Prelude.fail "reply function does not match"
                    3 -> Prelude.fmap (Prelude.Left . Exception.SomeException)
                           (Thrift.parseStruct _proxy ::
                              Parser.Parser Thrift.ApplicationException)
                    4 -> Prelude.fail
                           "testFunc: expected reply but got oneway function call"
                    _ -> Prelude.fail "testFunc: invalid message type"
       Thrift.parseMsgEnd _proxy
       Prelude.return _result