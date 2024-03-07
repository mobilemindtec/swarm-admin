package com.swarm.pages.services

import com.raquo.laminar.api.L.*
import com.raquo.laminar.nodes.ReactiveHtmlElement
import com.swarm.api.WebSocketClient.{WsClient, WsMsg, WsMsgType}
import com.swarm.pages.comps.LogLineView
import com.swarm.pages.comps.Theme.{breadcrumb, breadcrumbItem, terminal}
import com.swarm.util.ApiErrorHandle
import org.getshaka.nativeconverter.NativeConverter
import org.scalajs.dom.HTMLDivElement

import scala.concurrent.ExecutionContext.Implicits.global
import scala.scalajs.js
import scala.scalajs.js.Date
import scala.util.{Failure, Success}

object ServiceLogStream:

  final case class ServiceName(serviceName: String, serviceId: String, tail: Int = 100)
    derives NativeConverter

  private val message = Var[Option[String]](None)
  private val wsClient = WsClient()

  def apply(serviceName: String, serviceId: String): ReactiveHtmlElement[HTMLDivElement] =
    node(serviceName, serviceId)

  private def mount(serviceName: String, serviceId: String): Unit =
    wsClient.open().onComplete {
      ApiErrorHandle.handleUnit(message) {
        case Success(_) =>
          val msg = WsMsg(WsMsgType.logStart.toString, ServiceName(serviceName, serviceId).toNative)
          wsClient.send(msg)
      }
    }
  private def unmount(): Unit =
    wsClient.close()

  private def node(serviceName: String, serviceId: String) =
    div(
      onUnmountCallback(_ => unmount()),
      breadcrumb(
        breadcrumbItem(
          a(
            href(s"/docker/service/ps/$serviceId"),
            span(s"docker ps $serviceName")
          ),
          false
        ),
        breadcrumbItem(
          a(
            href("#"),
            span(s"service logs $serviceName")
          ),
          true
        )
      ),
      child.maybe <-- message.signal.map(_.map(s => {
        div(
          cls("alert alert-danger"),
          span(s)
        )
      })),
      hr(),
      terminal(
        onMountCallback(_ => mount(serviceName, serviceId)),
        children.command <-- wsClient.buss.events.map(msg => LogLineView(msg)).map(_.node)
      )
      // actions(),
    )
