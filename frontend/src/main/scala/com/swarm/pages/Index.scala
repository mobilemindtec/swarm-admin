package com.swarm.pages
import com.swarm.pages.comps.Theme.*
import com.swarm.pages.services.{ServiceLS, ServicePS}
import io.frontroute.*
import com.raquo.laminar.api.L.*
import com.raquo.laminar.nodes.ReactiveHtmlElement
import com.raquo.laminar.tags.HtmlTag
import com.swarm.api.ApiServer
import com.swarm.util.{Cookie, HtmlUtil}
import org.scalajs.dom
import org.scalajs.dom.MouseEvent
import org.scalajs.dom.window.document

import scala.util.{Failure, Success}

case class User(token: String)

val authenticatedUser = Var[Option[User]](None)

val requireAuthentication: Directive[User] =
  signal(authenticatedUser.signal).collect { case Some(user) => user }

object Index:

  def logout() =
    Login.logout()
    authenticatedUser.update(_ => None)

  def route =
    signal(authenticatedUser.signal) { implicit maybeUser =>
      firstMatch(
        pathEnd {
          requireAuthentication { user =>
            ServiceLS.page()
          }
        },
        path("docker" / "service" / "ps" / segment) { id =>
          requireAuthentication { user =>
            ServicePS.page(id)
          }
        },
        path("app" / "login") {
          Login.page()
        },
        extractUnmatchedPath { unmatched =>
          div(
            h2("not found"),
            div(unmatched.mkString("/", "/", ""))
          )
        }
      )
    }

  def skeleton[Ref <: dom.html.Element](children: ReactiveHtmlElement[Ref]*): HtmlElement =
    div(
      cls("container-fluid"),
      headerTag(
        cls("masthead"),
        div(
          cls("inner"),
          h3(
            cls("masthead-brand"),
            "Swarm Admin"
          ),
          child.maybe <-- authenticatedUser.signal.map(_.map(_ => {
            navTag(
              cls("nav nav-masthead justify-content-center"),
              a(
                cls("nav-link"),
                href("/"),
                "Home"
              ),
              a(
                cls("nav-link"),
                href("#"),
                "Logout",
                onClick --> (_ => logout())
              )
            )
          }))
        )
      ),
      mainTag(
        cls("inner cover"),
        div(
          cls("row-fluid"),
          div(
            cls("col-12"),
            children
          )
        )
      )
    )

  def page() =

    val token = Cookie.getCookie(Login.CookieAuthName)

    token.isEmpty match {
      case true =>
        Login.redirectLogin()
      case false =>
        authenticatedUser.update(_ => Some(User("ok")))
        Login.checkToken(() => {
          authenticatedUser.update(_ => None)
        })
    }
    skeleton(
      div(
        route
      )
    )
