package com.swarm.pages.adm.aws.codebuild.build

import com.raquo.laminar.api.L.*
import frontroute.*

object AwsBuildPage:

  def apply() = node()
  private def node() =
    div(
      path(long) { id =>
        AwsBuildList(id.toInt)
      }
    )
