package com.swarm.pages.services

import com.raquo.laminar.api.L.*
import com.swarm.api.ApiServer
import com.swarm.models.Models.Service
import com.swarm.pages.comps.Theme.terminal

import scala.concurrent.ExecutionContext.Implicits.global
import scala.scalajs.js
import scala.util.{Failure, Success}

object ServicePS:

  val servicesVar = Var(List[Service]())

  private def mount(id: String) =
    ApiServer.servicesPs(id).onComplete {
      case Success(data) => servicesVar.update(_ => data.data)
      case Failure(err)  => println(s"ERROR: ${err}")
    }

  def page(id: String) = 
    terminal(tb(id))
  
  def tb(id: String) =
    table(
      onMountCallback(_ => mount(id)),
      styleAttr("width: 100%; min-width: 100%"),
      thead(
        tr(
          List("ID", "NAME", "IMAGE", "NODE", "STATE", "ERROR").map(c => th(c))
        )
      ),
      tbody(
        children <-- servicesVar.signal.map(_.map(v => {
          tr(
            td(v.id),
            td(v.name),
            td(v.image.getOrElse("-")),
            td(v.node.getOrElse("-")),
            td(v.currentState.getOrElse("-")),
            td(v.err.getOrElse("-"))
          )
        }))
      )
    )
