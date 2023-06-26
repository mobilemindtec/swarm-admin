package com.swarm

import frontroute._
import org.scalajs.dom

import scalajs.js
import com.swarm.pages.Index
import com.raquo.laminar.api.L._
import com.swarm.util.Cookie

object App:

  lazy val node: HtmlElement =
    div(initRouting, Index.page())

@main def main(args: String*) =
  lazy val container = dom.document.getElementById("app")
  render(container, App.node.amend(LinkHandler.bind))
