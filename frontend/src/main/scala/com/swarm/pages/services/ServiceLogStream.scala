package com.swarm.pages.services

import com.raquo.laminar.api.L.*
import com.raquo.laminar.nodes.ReactiveHtmlElement
import com.swarm.api.WebSocketClient.{WsClient, WsMsg, WsMsgType}
import com.swarm.pages.comps.LogLineView
import com.swarm.pages.comps.Theme.{breadcrumb, breadcrumbItem, terminal}
import org.getshaka.nativeconverter.NativeConverter
import org.scalajs.dom.HTMLDivElement

import scala.concurrent.ExecutionContext.Implicits.global
import scala.scalajs.js
import scala.scalajs.js.Date
import scala.util.{Failure, Success}

object ServiceLogStream:

  final case class ServiceName(serviceName: String, tail: Int = 100) derives NativeConverter

  def apply(serviceName: String): ReactiveHtmlElement[HTMLDivElement] = node(serviceName)

  private val wsClient = WsClient()
  private def mount(serviceName: String): Unit =
    wsClient.open().onComplete {
      case Success(_) =>
        val msg = WsMsg(WsMsgType.logStart.toString, ServiceName(serviceName).toNative)
        wsClient.send(msg)
      case Failure(exception) => println(s"error: ${exception.getMessage}")
    }
  private def unmount(): Unit =
    wsClient.close()

  private def node(serviceName: String) =
    div(
      onUnmountCallback(_ => unmount()),
      breadcrumb(
        breadcrumbItem(
          a(
            href("#"),
            span("service logs")
          ),
          true
        )
      ),
      terminal(
        onMountCallback(_ => mount(serviceName)),
        children.command <-- wsClient.buss.events.map(msg => LogLineView(msg)).map(_.node)
      )
      // actions(),

    )
