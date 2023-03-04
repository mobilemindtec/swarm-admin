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

object Login:

  case class User(username: String = "", password: String = ""):
    def validate = this.username.nonEmpty && this.password.nonEmpty
  
  
  val CookieAuthName = "SwarmAdminToken"
  val CookieExpirationName = "SwarmAdminTokenExpiration"

  val message = Var[Option[String]](None)
  var stateVar = Var(User())

  def logout() =
    redirectLogin()
    Cookie.clearAll()

  def redirectLogin() =
    if !document.location.href.contains("/app/login") then document.location.href = "/app/login"

  def redirectHome() = document.location.href = "/"

  private def isValidToken =
    Cookie.getCookie(CookieExpirationName).exists(s => s.toLong > new Date().getTime())

  private def doCheck(cb: () => Unit) =
    if !isValidToken then
      logout()
      cb()

  def checkToken(cb: () => Unit) =
    window.setInterval(() => doCheck(cb), 1000 * 60)

  private def result(r: ApiAuthResult) =
    if r.hasError then message.update(_ => r.error)
    else
      Option((r.token, r.expires_at))
        .filter(x => x._1.nonEmpty && x._2.nonEmpty)
        .map(x => (x._1.get, x._2.get))
        .foreach((token, expires) =>
          val exp = expires * 1000
          Cookie.setCookie(CookieAuthName, token, exp)
          Cookie.setCookie(CookieExpirationName, exp.toString, exp)
          redirectHome()
        )

  private def loginSubmitter = Observer[User] { state =>
    if !state.validate then message.update(_ => Some("Enter with username and password"))
    else login(state)
  }

  private def login(u: User) =
    ApiServer.login(u.username, u.password).onComplete {
      case Success(r)   => result(r)
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
