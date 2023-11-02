package com.swarm.pages.comps

import com.raquo.laminar.api.L.*
import com.raquo.laminar.nodes.ReactiveHtmlElement
import com.raquo.laminar.tags.HtmlTag
import org.scalajs.dom
import org.scalajs.dom.{HTMLAnchorElement, HTMLLIElement, window}

object Theme:

  enum CmdType(val icon: String):
    case Loading extends CmdType("fa fa-spinner fa-pulse fa-fw")
    case Done extends CmdType("fa fa-check")
    case Link(val link: String) extends CmdType("fa fa-check")
    case Error extends CmdType("fa fa-close")
    case Info extends CmdType("fa fa-info")
    case None extends CmdType("")

  case class CmdLine(text: String, typ: CmdType)

  def terminal(children: Mod[HtmlElement]*) =
    div(cls("terminal table-responsive"), children)

  private def tryLink(s: CmdLine): CmdLine =
    if s.text.startsWith("link:local:")
    then
      val v = s.text.split(":")(2)
      s.copy(typ = CmdType.Link(v), text = s"open ${v}")
    else if s.text.startsWith("link:")
    then
      val v = s.text.split(":")(1)
      s.copy(typ = CmdType.Link(v), text = s"open ${v}")
    else s

  def command(lines: CmdLine*) =
    lines.map(tryLink).map { s =>
      span(
        cls("cmd-line"),
        (s.typ match
          case CmdType.Link(link) =>
            a(
              href("#"),
              span(cls(s.typ.icon)),
              onClick --> (_ => window.open(link, "_blank")),
              s"$$ ${s.text}  "
            )
          case _ => span(s"$$ ${s.text}  ", cls(s.typ.icon))
        ),
        br()
      )
    }

  def breadcrumbItem(label: String, active: Boolean): ReactiveHtmlElement[HTMLLIElement] =
    breadcrumbItem(span(label), active)
  def breadcrumbItem(label: Mod[HtmlElement], active: Boolean): ReactiveHtmlElement[HTMLLIElement] =
    li(
      cls(s"breadcrumb-item ${if active then "active" else ""}"),
      label
    )
  def breadcrumb(items: Mod[HtmlElement]*) =
    navTag(
      ul(
        cls("breadcrumb"),
        li(
          cls(s"breadcrumb-item ${if items.isEmpty then "active" else ""}"),
          a(href("/"), span("Home"))
        ),
        items
      )
    )

  def pageAction(label: Mod[HtmlElement], navigateTo: String) =
    a(
      cls("action pull-left"),
      href(navigateTo),
      label
    )

  def pageAction(label: Mod[HtmlElement], navigateTo: Signal[String]) =
    a(
      cls("action pull-left"),
      href <-- navigateTo,
      label
    )
  def pageAction(
    click: Any => Unit,
    label: Mod[HtmlElement]
  ): ReactiveHtmlElement[HTMLAnchorElement] =
    a(
      cls("action pull-left"),
      onClick --> click,
      label
    )
  def pageActions(items: ReactiveHtmlElement[HTMLAnchorElement]*) =
    div(
      cls("actions"),
      items
    )
