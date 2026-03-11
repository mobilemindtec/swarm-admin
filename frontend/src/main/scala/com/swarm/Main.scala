package com.swarm

import com.raquo.laminar.api.L.*
import com.swarm.pages.Index
import frontroute.*
import org.scalajs.dom

object App:

  lazy val node: HtmlElement =
    div(initRouting, Index.page())

@main def main(args: String*) =
  lazy val container = dom.document.getElementById("app")
  render(container, App.node.amend(LinkHandler.bind))
