package com.swarm.pages
import com.swarm.pages.comps.Theme.*
import com.swarm.pages.services.{ServiceLS, ServicePS}
import frontroute.*
import com.raquo.laminar.api.L.*
import com.raquo.laminar.nodes.ReactiveHtmlElement
import com.raquo.laminar.tags.HtmlTag
import com.swarm.api.ApiServer
import com.swarm.util.{Cookie, HtmlUtil}
import org.scalajs.dom
import org.scalajs.dom.{MouseEvent, window}
import org.scalajs.dom.window.document

import scala.util.{Failure, Success}
import com.swarm.services.AuthService
import com.swarm.services.AuthService.{AuthenticationEvent, UserAuth, authenticatedUser, authenticationEvents}

object Index:

  def route =
    div(
      child <-- authenticatedUser.map(render)
    )
  def render(maybeUser: Option[UserAuth]) =
    println(s"maybeUser = ${maybeUser.isEmpty}")
    div(
      firstMatch(
        pathEnd {
          provideOption(maybeUser) { us_er =>
            ServiceLS.page()
          }
        },
        path("docker" / "service" / "ps" / segment) { id =>
          provideOption(maybeUser) { _ =>
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
    )

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
          child.maybe <-- authenticatedUser.signal.map(
            _.map(_ =>
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
                  onClick --> (_ => AuthService.logout())
                )
              )
            )
          )
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
    skeleton(
      div(
        onMountCallback((_) => AuthService.enterApp()),
        route
      )
    )
