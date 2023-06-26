package com.swarm.pages.comps

import com.raquo.laminar.api.L.*
import com.raquo.laminar.tags.HtmlTag
import org.scalajs.dom

object Theme:

  def terminal(children: Mod[HtmlElement]*) =
    div(cls("terminal table-responsive"), children)

  def breadcrumbItem(label: String, active: Boolean) =
    li(
      cls(s"breadcrumb-item ${if active then "active" else ""}"),
      span(label)
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