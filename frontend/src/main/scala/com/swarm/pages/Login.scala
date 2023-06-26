package com.swarm.pages

import com.swarm.util.{Cookie, HtmlUtil}
import org.scalajs.dom.{MouseEvent, window}
import com.raquo.laminar.api.L.*
import com.swarm.api.ApiServer
import com.swarm.api.ApiServer.ApiAuthResult
import org.scalajs.dom.window.document

import scala.concurrent.ExecutionContext.Implicits.global
import scala.scalajs.js
import scala.scalajs.js.Date
import scala.util.{Failure, Success}
import com.swarm.services.{AuthService, Router}
import com.swarm.services.AuthService.UserLogin

object Login:

  private val message = Var[Option[String]](None)
  private val stateVar = Var(UserLogin())

  private def loginSubmitter = Observer[UserLogin] { state =>
    if !state.validate then message.update(_ => Some("Enter with username and password"))
    else login(state)
  }

  private def login(u: UserLogin) =
    AuthService.login(u).onComplete {
      case Success(_)   => Router.home()
      case Failure(err) => message.update(_ => Some(s"${err.getMessage}"))
    }

  def page() =
    div(
      cls("row"),
      div(
        cls("col-xs-12 col-md-4 offset-md-4"),
        form(
          cls("login"),
          h2(cls("title text-center"), "Login"),
          child.maybe <-- message.signal.map(_.map(s => {
            div(
              cls("alert alert-danger"),
              span(s)
            )
          })),
          div(
            cls("mb-1"),
            label(cls("form-label"), "username"),
            input(
              idAttr("username"),
              cls("form-control"),
              onInput.mapToValue --> stateVar.updater[String]((state, s) =>
                state.copy(username = s)
              )
            )
          ),
          div(
            cls("mb-1"),
            label(cls("form-label"), "password"),
            input(
              idAttr("password"),
              typ("password"),
              cls("form-control"),
              onInput.mapToValue --> stateVar.updater[String]((state, s) =>
                state.copy(password = s)
              )
            )
          ),
          div(
            button(
              "ENTER",
              typ("submit")
            )
          ),
          onSubmit.preventDefault.mapTo(stateVar.now()) --> loginSubmitter
        )
      )
    )
