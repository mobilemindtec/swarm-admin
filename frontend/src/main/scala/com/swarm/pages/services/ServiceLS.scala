package com.swarm.pages.services

import com.raquo.laminar.api.L.*
import com.swarm.api.ApiDockerService
import com.swarm.models.Models.Service
import com.swarm.pages.comps.Theme.{breadcrumb, breadcrumbItem, terminal}

import scala.concurrent.ExecutionContext.Implicits.global
import scala.scalajs.js
import scala.util.{Failure, Success}

object ServiceLS:

  private val servicesVar = Var(List[Service]())

  def apply() = node()

  private def apiSync() =
    ApiDockerService.ls().onComplete {
      case Success(data) => servicesVar.update(_ => data.data)
      case Failure(err)  => println(s"ERROR: $err")
    }
  private def mount() = apiSync()

  private def node() =
    div(
      breadcrumb(
        breadcrumbItem(
          a(
            href("#"),
            span(s"docker service ls"),
            onClick --> (_ => apiSync())
          ),
          true
        )
      ),
      terminal(tb())
    )

  private def tb() =
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
