package com.swarm.pages.services

import com.raquo.laminar.api.L.*
import com.swarm.api.ApiServer
import com.swarm.models.Models.Service
import com.swarm.pages.comps.Theme.terminal

import scala.concurrent.ExecutionContext.Implicits.global
import scala.scalajs.js
import scala.util.{Failure, Success}

object ServiceLS:

  val servicesVar = Var(List[Service]())

  private def mount() =
    ApiServer.servicesLs().onComplete {
      case Success(data) => servicesVar.update(_ => data.data)
      case Failure(err)  => println(s"ERROR: ${err}")
    }

  def page() = terminal(tb())

  def tb() =
    table(
      onMountCallback(_ => mount()),
      styleAttr("width: 100%; min-width: 100%"),
      thead(
        tr(
          List("ID", "NAME", "REPLICAS").map(c => th(c))
        )
      ),
      tbody(
        children <-- servicesVar.signal.map(_.map(v => {
          tr(
            td(a(href(s"/docker/service/ps/${v.id}"), v.id)),
            td(v.name),
            td(v.replicas.getOrElse("-"))
          )
        }))
      )
    )
