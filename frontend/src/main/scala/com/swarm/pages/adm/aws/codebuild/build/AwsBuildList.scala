package com.swarm.pages.adm.aws.codebuild.build

import com.raquo.laminar.api.L.*
import com.raquo.laminar.nodes.ReactiveHtmlElement
import com.swarm.api.ApiServer.ApiResult
import com.swarm.api.{ApiAwsBuild, ApiAwsCodeBuildApp}
import com.swarm.models.{AwsBuild, AwsCodeBuildApp}
import com.swarm.pages.comps.Theme.{breadcrumb, breadcrumbItem, pageAction, pageActions}
import com.swarm.util.ApiErrorHandle
import org.scalajs.dom.{HTMLDivElement, window}

import scala.concurrent.ExecutionContext.Implicits.global
import scala.language.postfixOps
import scala.util.{Failure, Success}

object AwsBuildList:

  enum Event:
    case Update(id: Int)
    case Stop(id: Int)
    case Start
    case Nothing

  private val message = Var[Option[String]](None)
  private val awsBuilds = Var(List[AwsBuild]())
  private val awsApp = Var[Option[AwsCodeBuildApp]](None)
  private val eventVar = Var[Option[Event]](Some(Event.Nothing))

  def apply(id: Int): ReactiveHtmlElement[HTMLDivElement] =
    loadAwsApp(id, Some(load))
    node()

  private def loadAwsApp(id: Int, loadedCb: Option[() => Unit] = None): Unit =
    ApiAwsCodeBuildApp.get(id).onComplete {
      ApiErrorHandle.handle(message) { case Success(ApiResult(app, _, _, _)) =>
        awsApp.update(_ => app)
        autoUpdateApp(app.filter(_.building), 5 * 1000)
        loadedCb.foreach { cb => cb() }
      }
    }

  private def load() =
    awsApp.now().foreach { app =>
      ApiAwsBuild.list(app).onComplete {
        ApiErrorHandle.handle(message) { case Success(ApiResult(Some(builds), _, _, _)) =>
          builds.filter(_.building).foreach(autoUpdateBuild)
          awsBuilds.update(_ => builds)
        }
      }
    }

  private def autoUpdateApp(app: Option[AwsCodeBuildApp], timeout: Int) =
    app.foreach { p =>
      window.setTimeout(
        () => {
          print("autoUpdateApp")
          loadAwsApp(p.id, None)
        },
        timeout
      )
    }

  private def autoUpdateBuild(build: AwsBuild): Unit =
    window.setTimeout(
      () => {
        print("autoUpdateBuild")
        update(build)
      },
      5 * 1000
    )

  private def remove(awsBuild: AwsBuild) =
    if window.confirm("Are you sure?") then
      ApiAwsBuild.delete(awsBuild).onComplete {
        ApiErrorHandle.handleUnit(message) { case Success(_) =>
          awsBuilds.update(lst => lst.filterNot(_.id == awsBuild.id))
        }
      }

  private def update(awsBuild: AwsBuild) =
    eventVar.update(_ => Some(Event.Update(awsBuild.id)))
    ApiAwsBuild.update(awsBuild).onComplete {
      ApiErrorHandle.handle(message) { case Success(ApiResult(Some(build), _, _, _)) =>
        eventVar.update(_ => Some(Event.Nothing))
        awsBuilds.update(lst => lst.updated(lst.indexWhere(_.id == awsBuild.id), build))
        if build.building
        then autoUpdateBuild(build)
      }
    }

  private def start() =
    if window.confirm("Are you sure?") then
      eventVar.update(_ => Some(Event.Start))
      awsApp.now().foreach { app =>
        ApiAwsBuild.start(app).onComplete {
          ApiErrorHandle.handle(message) { case Success(ApiResult(Some(build), _, _, _)) =>
            eventVar.update(_ => Some(Event.Nothing))
            awsBuilds.update(lst => build :: lst)
            awsApp.update(_.map(_.copy(building = true)))
            autoUpdateBuild(build)
            autoUpdateApp(Some(app), 5 * 1000)
          }
        }
      }
  private def stop(awsBuild: AwsBuild) =
    if window.confirm("Are you sure?") then
      eventVar.update(_ => Some(Event.Stop(awsBuild.id)))
      ApiAwsBuild.stop(awsBuild).onComplete {
        ApiErrorHandle.handle(message) { case Success(ApiResult(Some(build), _, _, _)) =>
          eventVar.update(_ => None)
          awsBuilds.update(lst => lst.updated(lst.indexWhere(_.id == awsBuild.id), build))
          autoUpdateApp(awsApp.now(), 0)
        }
      }

  private def header =
    breadcrumb(
      breadcrumbItem(
        a(
          href("/adm/aws/codebuild/app"),
          span("aws codebuild apps")
        ),
        false
      ),
      breadcrumbItem(
        child.maybe <-- awsApp.signal.map(
          _.map(app => span(s"aws builds for ${app.awsProjectName} "))
        ),
        true
      )
    )

  private def buildStatusElem(awsBuild: AwsBuild) =
    if awsBuild.buildStatus == "IN_PROGRESS"
    then
      child.maybe <-- eventVar.signal.map(_.map {
        case Event.Stop(id) if id == awsBuild.id =>
          span(cls("fa fa-cog fa-spin fa-fw"))
        case _ => actionStop(awsBuild)
      })
    else
      span(
        cls("fa fa-circle"),
        title("no build")
      )
  private def actionStop(awsBuild: AwsBuild) =
    a(
      href("#"),
      i(cls("fa fa-ban")),
      onClick --> (_ => stop(awsBuild)),
      title("build cancel")
    )
  private def actionUpdate(awsBuild: AwsBuild) =
    a(
      href("#"),
      i(cls("fa fa-refresh")),
      onClick --> (_ => update(awsBuild)),
      title("build update")
    )

  private def tbRow(awsBuild: AwsBuild) =
    tr(
      td(awsBuild.id.toString),
      td(awsBuild.currentPhase),
      td(awsBuild.buildStatus),
      td(awsBuild.appVersionTag),
      td(awsBuild.startTime),
      td(awsBuild.endTime),
      td(
        cls("text-center"),
        styleAttr("width: 50px"),
        buildStatusElem(awsBuild)
      ),
      td(
        cls("text-center"),
        styleAttr("width: 50px"),
        child.maybe <-- eventVar.signal.map(_.map {
          case Event.Update(id) if id == awsBuild.id =>
            span(cls("fa fa-cog fa-spin fa-fw"))
          case _ => actionUpdate(awsBuild)
        })
      ),
      td(
        cls("text-center"),
        styleAttr("width: 50px"),
        a(
          href(s"/adm/aws/build/logs/${awsBuild.id}"),
          i(cls("fa fa-cogs")),
          title("show build logs")
        )
      ),
      td(
        cls("text-center"),
        styleAttr("width: 50px"),
        a(
          href("#"),
          i(cls("fa fa-trash")),
          onClick --> (_ => remove(awsBuild)),
          title("build remove")
        )
      )
    )

  private def tb() =
    table(
      cls("table table-striped table-dark table-bordered table-hover table-sm table-adm"),
      thead(
        tr(
          List("#", "phase", "status", "version", "start time", "end time", "", "", "", "").map {
            s =>
              th(s)
          }
        )
      ),
      tbody(
        children <-- awsBuilds.signal.map(_.map(tbRow))
      )
    )
  private def node() =
    div(
      // onMountCallback(_ => mount()),
      header,
      pageActions(
        pageAction(
          { _ => start() },
          child.maybe <-- eventVar.signal
            .combineWith(awsApp.signal)
            .map({ (event: Option[Event], app: Option[AwsCodeBuildApp]) =>
              event.map {
                case Event.Start =>
                  span("build starting.. ", span(cls("fa fa-cog fa-spin fa-fw")))
                case _ =>
                  app
                    .filter(_.building)
                    .map(_ => span("build in progress.. ", span(cls("fa fa-cog fa-spin fa-fw"))))
                    .getOrElse(span("build start"))
              }.orElse(Some(span("build start")))

            })
        )
      ),
      child.maybe <-- message.signal.map(_.map(s => {
        div(
          cls("alert alert-danger"),
          span(s)
        )
      })),
      tb()
    )
