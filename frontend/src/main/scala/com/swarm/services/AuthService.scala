package com.swarm.services

import com.raquo.laminar.api.L.*
import com.swarm.api.ApiServer
import com.swarm.api.ApiServer.ApiAuthResult
import com.swarm.util.Cookie
import org.scalajs.dom.window
import org.scalajs.dom.window.document

import scala.concurrent.ExecutionContext.Implicits.global
import scala.scalajs.js
import scala.scalajs.js.Date
import scala.concurrent.{Future, Promise}
import scala.util.{Failure, Success, Try}
import scala.concurrent.duration.*

object AuthService:

  class AuthException(message: String) extends RuntimeException(message)
  case class UserAuth()

  case class UserLogin(username: String = "", password: String = ""):
    def validate: Boolean = this.username.nonEmpty && this.password.nonEmpty

  sealed trait AuthenticationEvent extends Product with Serializable

  object AuthenticationEvent:
    case object SignedOut extends AuthenticationEvent

    case object SignedIn extends AuthenticationEvent

  val authenticationEvents = new EventBus[AuthenticationEvent]
  val authenticatedUser: Signal[Option[UserAuth]] =
    authenticationEvents.events.scanLeft(Option.empty[UserAuth]) {
      case (_, AuthenticationEvent.SignedOut) =>
        Option.empty
      case (_, AuthenticationEvent.SignedIn) =>
        Some(UserAuth())
    }

  private val CookieAuthName = "SwarmAdminToken"
  private val CookieExpirationName = "SwarmAdminTokenExpiration"

  def logout(): Unit =
    Cookie.clearAll()
    Router.login()

  def login(u: UserLogin): Future[Unit] =
    val p = Promise[Unit]()
    ApiServer
      .login(u.username, u.password)
      .onComplete {
        case Success(r) =>
          if r.error.nonEmpty then p.failure(AuthException(r.error.get))
          else
            pesistAuthToken(r)
            p.success(())
        case Failure(exception) =>
          p.failure(exception)
      }
    p.future

  private def isValidToken =
    Cookie.getCookie(CookieExpirationName).exists(s => s.toLong > new Date().getTime())

  private def authCheck(cb: () => Unit): Unit =
    if !isValidToken then
      logout()
      cb()

  def startAuthCheckerTask(cb: () => Unit): Unit =
    window.setInterval(() => authCheck(cb), 1000 * 60)

  def pesistAuthToken(r: ApiAuthResult) =
    Option[(Option[String], Option[Long])]((r.token, r.expires_at))
      .filter((x, y) => x.nonEmpty && y.nonEmpty)
      .map((x, y) => (x.get, y.get))
      .foreach((token, expires) =>
        val exp = expires * 1000
        Cookie.setCookie(CookieAuthName, token, exp)
        Cookie.setCookie(CookieExpirationName, exp.toString, exp)
      )

  def enterApp() =
    val token = Cookie.getCookie(CookieAuthName)
    if token.isEmpty then Router.login()
    else
      authenticationEvents.emit(AuthenticationEvent.SignedIn)
      startAuthCheckerTask { () =>
        authenticationEvents.emit(AuthenticationEvent.SignedOut)
      }
