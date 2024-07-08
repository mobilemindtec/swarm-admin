package com.swarm.pages.adm.stats

import com.raquo.laminar.api.L.*
import frontroute._

object StatsPage:

  def apply() = node()
  private def node() =
    div(
      path("form") {
        StatsForm()
      },
      path("form" / long) { id =>
        StatsForm(id.toInt)
      },
      path("report" / long) { id =>
        StatsReportPage(id.toInt)
      },
      pathEnd {
        StatsList()
      }
    )
