package com.swarm.pages.services

import com.raquo.laminar.api.L.*
import com.swarm.api.ApiServer
import com.swarm.models.Models.Service
import com.swarm.pages.comps.Theme.{breadcrumb, terminal}

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

  def page() =
    div(
      breadcrumb(),
      terminal(tb())
    )

  def tb() =
    table(
      onMountCallback(_ => mount()),
      styleAttr("width: 100%; min-width: 100%"),
      thead(
        tr(
          List("ID", "NAME", "IMAGE", "REPLICAS", "PORTS").map(c => th(c))
        )
      ),
      tbody(
        children <-- servicesVar.signal.map(_.map(v => {
          tr(
            td(
              dataAttr("title")("ID"),
              a(href(s"/docker/service/ps/${v.id}"), v.id)
            ),
            td(
              dataAttr("title")("NAME"),
              v.name
            ),
            td(
              dataAttr("title")("IMAGE"),
              v.image
            ),
            td(
              dataAttr("title")("REPLICAS"),
              v.replicas.getOrElse("-")
            ),
            td(
              dataAttr("title")("PORTS"),
              v.ports.getOrElse("-")
            )
          )
        }))
      )
    )
