package com.swarm.pages.comps

import com.swarm.api.WebSocketClient.{WsMsg, WsMsgType}
import org.scalajs.dom.{HTMLElement, HTMLSpanElement}
import com.raquo.laminar.api.L.*
import com.raquo.laminar.nodes.{ReactiveElement, ReactiveHtmlElement}

import scala.scalajs.js.Date

final case class LogLineView(
  nodes: List[ReactiveElement[HTMLElement]],
  typ: String,
  color: String,
  hidden: Boolean = false,
  datetime: Option[Date] = None
):
  def node: CollectionCommand.Prepend[ReactiveHtmlElement[HTMLSpanElement]] =
    CollectionCommand.Prepend(
      span(
        span(
          s"[${typ}] ",
          styleAttr(s"color: $color")
        ) :: nodes
      )
    )

object LogLineView:
  def apply(wsMsg: WsMsg): LogLineView = fromWsMsg(wsMsg)
  private def fromWsMsg(msg: WsMsg): LogLineView =
    val nodes = messageParts(msg) match
      case List(_) => span(s"${msg.msg}") :: br() :: Nil
      case List(_, dt, mg) =>
        span(s"${dt} ", styleAttr(s"color: #e1b12c")) :: span(mg) :: br() :: Nil
      case _ => span(s"${msg.msg}") :: Nil
    val color = colorize(msg.typ)
    new LogLineView(nodes, msg.msgType, color)

  private def colorize(t: WsMsgType): String = t match
    case WsMsgType.info    => "#00a8ff"
    case WsMsgType.error   => "#e74c3c"
    case WsMsgType.log     => "#44bd32"
    case WsMsgType.stopped => "#e74c3c"
    case _                 => "inherits"

  private def extractDatetime(parts: Array[String]) =
    val date = parts(1)
    if date.length == 10 then s"$date ${parts(2)}"
    else date
  private def messageParts(msg: WsMsg) =
    val msgText = msg.msg.toString
    val parts = msgText.split(" ")
    (msg.typ, parts.length) match
      case (WsMsgType.log, 3) =>
        val typeLabel = parts(0)
        val date = extractDatetime(parts)
        val idxStart = parts(1).length match
          case 10 => 3 // date yyyy-MM-ddd HH:mm
          case _  => 2 // date yyyy-MM-dddTHH:mm
        val rest = parts.slice(idxStart, parts.length).mkString(" ")
        typeLabel :: date :: rest :: Nil
      case _ => msgText :: Nil
