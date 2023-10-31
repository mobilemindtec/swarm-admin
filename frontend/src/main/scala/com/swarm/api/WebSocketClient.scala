package com.swarm.api

import com.raquo.airstream.eventbus.EventBus
import com.swarm.configs.AppConfigs
import org.getshaka.nativeconverter.NativeConverter
import org.scalajs.dom.{MessageEvent, WebSocket}

import scala.concurrent.{Future, Promise}
import scala.scalajs.js
import scala.scalajs.js.JSON
object WebSocketClient:
  enum WsMsgType derives NativeConverter:
    case logStart, logStop, error, info, log, stopped

  case class WsMsg(msgType: String, msg: js.Any) derives NativeConverter:
    def typ = WsMsgType.valueOf(msgType)

  class WsClient():

    val buss = new EventBus[WsMsg]

    private var _ws: Option[WebSocket] = None
    private def ws = _ws.get

    def open(): Future[_] =
      val p = Promise[Any]()
      _ws = Some(new WebSocket(AppConfigs.wsUrl))

      ws.onerror = { err =>
        println(s"on error: ${err}")
        buss.emit(WsMsg(WsMsgType.error.toString, err))
      }

      ws.onopen = { _ =>
        println("opened")
        buss.emit(WsMsg(WsMsgType.info.toString, "Successful connection"))
        p.success(true)
      }

      ws.onclose = { _ =>
        println("closed")
        buss.emit(WsMsg(WsMsgType.info.toString, "Connection was closed"))
      }

      ws.onmessage = { e =>
        println("new msg")
        val data = JSON.parse(e.data.toString)
        val msg = NativeConverter[WsMsg].fromNative(data)
        buss.emit(msg)
      }

      p.future

    def close(): Unit = ws.close()

    def send(msg: WsMsg): Unit =
      ws.send(JSON.stringify(msg.toNative))
