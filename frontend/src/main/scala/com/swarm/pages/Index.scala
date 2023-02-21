package com.swarm.pages
import com.swarm.pages.comps.Theme._
import com.swarm.pages.services.{ServiceLS, ServicePS}
import io.frontroute.*
import com.raquo.laminar.api.L.*

object Index:

  def page() =
    div(
      pathEnd {
        ServiceLS.page()
      },
      path("docker" / "service" / "ps" / segment) { id =>
        ServicePS.page(id)
      },
      noneMatched {
        div(
          h2("not found")
        )
      }
    )
