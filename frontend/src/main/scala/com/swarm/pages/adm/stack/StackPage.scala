package com.swarm.pages.adm.stack

import com.raquo.laminar.api.L.*
import frontroute._

object StackPage:

  def apply() = node()
  private def node() =
    div(
      path("form") {
        StackForm()
      },
      path("form" / long) { id =>
        StackForm(id.toInt)
      },
      pathEnd {
        StackList()
      }
    )
