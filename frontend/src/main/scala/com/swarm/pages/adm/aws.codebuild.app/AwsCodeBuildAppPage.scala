package com.swarm.pages.adm.aws.codebuild.app

import com.raquo.laminar.api.L.*
import frontroute._

object AwsCodeBuildAppPage:

  def apply() = node()
  private def node() =
    div(
      path("form") {
        AwsCodeBuildAppForm()
      },
      path("form" / long) { id =>
        AwsCodeBuildAppForm(id.toInt)
      },
      pathEnd {
        AwsCodeBuildAppList()
      }
    )
