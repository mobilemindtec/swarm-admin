package com.swarm

import io.frontroute.*
import org.scalajs.dom

import scalajs.js
import com.swarm.pages.Index
import com.raquo.laminar.api.L.*
import com.swarm.util.Cookie

object App:

  lazy val node: HtmlElement = Index.page()

@main def main(args: String*) =
  lazy val container = dom.document.getElementById("app")
  render(container, App.node.amend(LinkHandler.bind))
