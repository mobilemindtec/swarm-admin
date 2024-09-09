package com.swarm.pages
import com.raquo.laminar.api.L.*
import com.raquo.laminar.nodes.ReactiveHtmlElement
import com.swarm.laminar.Drawer
import com.swarm.pages.Index.DrawerMenuItem.{Authenticator, AwsCodeBuildApp, Home, Stack, Stats}
import com.swarm.pages.adm.aws.codebuild.app.AwsCodeBuildAppPage
import com.swarm.pages.adm.aws.codebuild.build.{AwsBuildLogStream, AwsBuildPage}
import com.swarm.pages.adm.stack.StackPage
import com.swarm.pages.adm.stats.StatsPage
import com.swarm.pages.services.{ServiceLS, ServiceLogStream, ServicePS}
import com.swarm.pages.stacks.StackManager
import com.swarm.services.AuthService
import com.swarm.services.AuthService.{UserAuth, authenticatedUser}
import frontroute.*
import org.scalajs.dom
import org.scalajs.dom.{Event, html}

object Index:

  enum DrawerMenuItem:
    case Home
    case Stack
    case Stats
    case AwsCodeBuildApp
    case Authenticator
    // case StatsReport

  val drawerMenuItemVar = Var[DrawerMenuItem](DrawerMenuItem.Home)
  val menuItemCls = "list-group-item" :: "list-group-item-action" :: "rounded-0" :: Nil

  def getDrawerMenuItemCls(item: DrawerMenuItem) =
    drawerMenuItemVar.signal.map { curr =>
      if curr == item then menuItemCls :+ "active" else menuItemCls
    }

  def route =
    div(
      child <-- authenticatedUser.map(render)
    )
  def render(maybeUser: Option[UserAuth]) =
    div(
      firstMatch(
        pathEnd {
          provideOption(maybeUser) { us_er =>
            ServiceLS()
          }
        },
        path("docker" / "service" / "ps" / segment) { id =>
          provideOption(maybeUser) { _ =>
            ServicePS(id)
          }
        },
        path("docker" / "service" / "log" / "stream" / segment / segment) { (name, id) =>
          provideOption(maybeUser) { _ =>
            ServiceLogStream(name, id)
          }
        },
        path("docker" / "stack" / "mgr" / segment) { id =>
          provideOption(maybeUser) { _ =>
            StackManager(id)
          }
        },
        path("adm" / "aws" / "build" / "logs" / segment) { id =>
          provideOption(maybeUser) { _ =>
            drawerMenuItemVar.update(_ => DrawerMenuItem.AwsCodeBuildApp)
            AwsBuildLogStream(id)
          }
        },
        pathPrefix("adm" / "stack") {
          provideOption(maybeUser) { _ =>
            drawerMenuItemVar.update(_ => DrawerMenuItem.Stack)
            StackPage()
          }
        },
        /*
        pathPrefix("adm" / "stats") {
          provideOption(maybeUser) { _ =>
            drawerMenuItemVar.update(_ => DrawerMenuItem.Stats)
            StatsPage()
          }
        },*/
        pathPrefix("adm" / "aws" / "codebuild" / "app") {
          provideOption(maybeUser) { _ =>
            drawerMenuItemVar.update(_ => DrawerMenuItem.AwsCodeBuildApp)
            AwsCodeBuildAppPage()
          }
        },
        pathPrefix("adm" / "aws" / "build") {
          provideOption(maybeUser) { _ =>
            drawerMenuItemVar.update(_ => DrawerMenuItem.AwsCodeBuildApp)
            AwsBuildPage()
          }
        },
        pathPrefix("adm" / "authenticator") {
          provideOption(maybeUser) { _ =>
            drawerMenuItemVar.update(_ => DrawerMenuItem.Authenticator)
            AuthenticatorPage()
          }
        },
        path("app" / "login") {
          Login()
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
    Drawer(
      drawerMenu,
      drawerContent(children*),
      Drawer.mockBottom,
      authenticatedUser.map(p => p.nonEmpty)
    )

  def drawerMenu =
    div(
      cls := "h-100 bg-dark",
      div(cls := "p-4 bg-dark", a(href := "#", h1(cls := "text-white", "Swarm Admin"))),
      ul(
        cls := "list-group",
        onClick --> Drawer.toogle,
        a(
          cls <-- getDrawerMenuItemCls(Home),
          href("/"),
          "Home"
        ),
        a(
          cls <-- getDrawerMenuItemCls(Stack),
          href("/adm/stack"),
          "Stacks"
        ),
        /*a(
          cls <-- getDrawerMenuItemCls(Stats),
          href("/adm/stats"),
          "Stats"
        ),*/
        a(
          cls <-- getDrawerMenuItemCls(AwsCodeBuildApp),
          href("/adm/aws/codebuild/app"),
          "Aws CodeBuild Apps"
        ),
        a(
          cls <-- getDrawerMenuItemCls(Authenticator),
          href("/adm/authenticator"),
          "Authenticator"
        ),
        a(
          cls("list-group-item list-group-item-action rounded-0"),
          href("#"),
          "Logout",
          onClick --> (_ => AuthService.logout())
        )
      )
    )

  def drawerContent[Ref <: dom.html.Element](children: ReactiveHtmlElement[Ref]*): HtmlElement =
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

  def page() =
    skeleton(
      div(
        onMountCallback(_ => AuthService.enterApp()),
        route
      )
    )
