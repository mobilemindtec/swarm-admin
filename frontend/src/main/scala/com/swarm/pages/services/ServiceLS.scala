package com.swarm.pages.services

import com.raquo.laminar.api.L.*
import com.swarm.api.ApiDockerService
import com.swarm.api.ApiServer.ApiResult
import com.swarm.models.Service
import com.swarm.pages.adm.stack.StackForm.message
import com.swarm.pages.comps.Theme.{breadcrumb, breadcrumbItem, terminal}
import com.swarm.pages.stacks.StackManager.message
import com.swarm.util.ApiErrorHandle

import scala.concurrent.ExecutionContext.Implicits.global
import scala.scalajs.js
import scala.util.{Failure, Success}

object ServiceLS:

  private val servicesVar = Var(List[Service]())
  private val message = Var[Option[String]](None)

  def apply() = node()

  private def apiSync() =
    ApiDockerService.ls().onComplete {
      ApiErrorHandle.handle(message) { case Success(ApiResult(Some(service), _, _, _)) =>
        servicesVar.update(_ => service)
      }
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
      child.maybe <-- message.signal.map(_.map(s => {
        div(
          cls("alert alert-danger"),
          span(s)
        )
      })),
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
