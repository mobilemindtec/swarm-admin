package com.swarm

import io.frontroute.*
import org.scalajs.dom

import scalajs.js
import com.swarm.pages.{Index}
import com.raquo.laminar.api.L.*

object App:

  lazy val node: HtmlElement =
    div(
      pathEnd {
        Index.page()
      },
      noneMatched {
        div(
          h2("not found")
        )
      }
    )

@main def main(args: String*) =
  lazy val container = dom.document.getElementById("app")
  render(container, App.node.amend(LinkHandler.bind))
