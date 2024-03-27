package com.swarm.pages

import com.raquo.laminar.api.L.*
import com.swarm.api.ApiAuth
import com.swarm.services.AuthService.UserLogin
import com.swarm.services.{AuthService, Router}

import scala.concurrent.ExecutionContext.Implicits.global
import scala.util.{Failure, Success}

object Login:

  private val message = Var[Option[String]](None)
  private val stateVar = Var(UserLogin())
  private val useAuthenticator = Var[Option[Boolean]](None)

  def apply() = node()

  private def loginSubmitter = Observer[UserLogin] { state =>
    if !state.validate then message.update(_ => Some("Enter with username and password"))
    else login(state)
  }

  private def login(u: UserLogin) =
    AuthService.login(u).onComplete {
      case Success(_)   => Router.home()
      case Failure(err) => message.update(_ => Some(s"${err.getMessage}"))
    }

  private def checkAuthenticator =
    ApiAuth.authenticatorStatus.onComplete {
      case Success(resp) =>
        if resp.enabled
        then useAuthenticator.update(_ => Some(true))
      case Failure(err) => message.update(_ => Some(s"${err.getMessage}"))
    }
  private def inputCode =
    div(
      cls("mb-1"),
      label(cls("form-label"), "code"),
      input(
        idAttr("code"),
        cls("form-control"),
        onInput.mapToValue --> stateVar.updater[String]((state, s) => state.copy(code = s))
      )
    )
  def node() =
    div(
      onMountCallback(_ => checkAuthenticator),
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
          child.maybe <-- useAuthenticator.signal.map(_ => Some(inputCode)),
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
