package com.swarm.laminar
import com.raquo.laminar.api.L.*
import com.raquo.laminar.nodes.ReactiveHtmlElement
import com.raquo.laminar.receivers.ChildReceiver.maybe
import org.scalajs.dom.{Event, HTMLDivElement, HTMLElement, document, html, window}
import org.scalajs.dom

import scala.annotation.unused

object Drawer:

  def apply[Ref <: dom.html.Element](
    menu: ReactiveHtmlElement[Ref],
    content: ReactiveHtmlElement[Ref],
    bottom: ReactiveHtmlElement[Ref],
    navbarSignal: Signal[Boolean]
  ): ReactiveHtmlElement[HTMLElement] =
    div(
      div(
        idAttr := "side-drawer",
        cls := "position-fixed",
        menu
      ),
      div(
        cls := "position-absolute w-100",
        styleAttr := "bottom: 0",
        bottom
      ),
      div(
        idAttr := "side-drawer-void",
        cls := "position-fixed d-none",
        onClick --> toogle
      ),
      maybe <-- navbarSignal.map(b => if b then Some(nav) else Some(div())),
      content
    )

  def nav =
    navTag(
      cls := "navbar navbar-dark fixed-top",
      button(
        cls := "navbar-toggler",
        tpe := "button",
        onClick --> toogle,
        span(cls := "navbar-toggler-icon")
      ),
      span(cls := "navbar-text")
    )
  def toogle(@unused ev: Event) =
    val drawer = document
      .getElementById("side-drawer")
      .asInstanceOf[html.Div]

    val opened = drawer.style.left == "0px"

    drawer.style.left = if opened then "-336px" else "0px"

    document
      .getElementById("side-drawer-void")
      .classList
      .add(if opened then "d-none" else "d-block")
    document
      .getElementById("side-drawer-void")
      .classList
      .remove(if opened then "d-block" else "d-none")

  def mockMenu =
    div(
      cls := "h-100 bg-white",
      div(cls := "p-4 bg-dark", a(href := "#", h1(cls := "text-white", "Title"))),
      ul(
        cls := "list-group",
        onClick --> toogle,
        a(
          href := "#",
          cls := "list-group-item list-group-item-action border-0 rounded-0 active",
          "Link"
        ),
        a(
          href := "#",
          cls := "list-group-item list-group-item-action border-0 rounded-0",
          "Link"
        )
      )
    )

  def mockContent =
    mainTag(cls := "container my-5 bg-white", div(cls := "p-4 p-md-5"))

  def mockBottom =
    div(
      cls := "container px-4 py-3 text-muted",
      small(
        "Side Drawer by",
        a(
          cls := "text-muted text-decoration-none",
          href := "http://github.com/danielflachica/",
          target := "_blank",
          "Ricardo Bocchi"
        )
      )
    )
