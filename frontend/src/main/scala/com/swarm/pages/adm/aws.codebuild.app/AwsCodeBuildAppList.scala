package com.swarm.pages.adm.aws.codebuild.app

import com.raquo.laminar.api.L.*
import com.raquo.laminar.nodes.ReactiveHtmlElement
import com.swarm.api.ApiAwsCodeBuildApp
import com.swarm.api.ApiServer.ApiResult
import com.swarm.models.AwsCodeBuildApp
import com.swarm.pages.comps.Theme.{breadcrumb, breadcrumbItem, pageAction, pageActions}
import com.swarm.util.ApiErrorHandle
import org.scalajs.dom.{HTMLDivElement, window}

import scala.concurrent.ExecutionContext.Implicits.global
import scala.util.{Failure, Success}

object AwsCodeBuildAppList:

  private val message = Var[Option[String]](None)
  private val awsApps = Var(List[AwsCodeBuildApp]())

  def apply(): ReactiveHtmlElement[HTMLDivElement] = node()

  def mount() =
    load()
  private def load() =
    ApiAwsCodeBuildApp.list().onComplete {
      ApiErrorHandle.handle(message) {
        case Success(ApiResult(Some(apps), _, _, _)) =>
          awsApps.update(_ => apps)
      }
    }
  private def remove(awsApp: AwsCodeBuildApp) =
    if window.confirm("Are you sure?") then
      ApiAwsCodeBuildApp.delete(awsApp).onComplete {
        ApiErrorHandle.handleUnit(message) {
          case Success(_) =>
            awsApps.update(lst => lst.filterNot(_.id == awsApp.id))
        }
      }

  private def header =
    breadcrumb(
      breadcrumbItem(
        "aws codebuild apps",
        true
      )
    )

  private def buildInfo(awsApp: AwsCodeBuildApp) =
    if awsApp.building
    then
      span(
        cls("fa fa-cog fa-spin fa-fw"),
        title("app is on building")
      )
    else
      span(
        cls("fa fa-circle"),
        title("no build")
      )
  private def tbRow(awsApp: AwsCodeBuildApp) =
    tr(
      td(awsApp.id.toString),
      td(
        cls("text-center"),
        buildInfo(awsApp)
      ),
      td(awsApp.awsEcrRepositoryName),
      td(awsApp.versionTag),
      td(awsApp.codeBase),
      td(awsApp.lastBuildAt),
      td(awsApp.updatedAt),
      td(
        cls("text-center"),
        a(
          href(s"/adm/aws/build/${awsApp.id}"),
          i(cls("fa fa-list")),
          title("show builds")
        )
      ),
      td(
        cls("text-center"),
        a(
          href(s"/adm/aws/codebuild/app/form/${awsApp.id}"),
          i(cls("fa fa-edit"))
        )
      ),
      td(
        cls("text-center"),
        a(
          href("#"),
          i(cls("fa fa-trash")),
          onClick --> (_ => remove(awsApp))
        )
      )
    )

  private def tb() =
    table(
      cls("table table-striped table-dark table-bordered table-hover table-sm table-adm"),
      thead(
        tr(
          List("#", "", "repository", "version", "code base", "last build", "last update", "", "").map { s =>
            th(s)
          }
        )
      ),
      tbody(
        children <-- awsApps.signal.map(_.map(tbRow))
      )
    )
  private def node() =
    div(
      onMountCallback(_ => mount()),
      header,
      pageActions(
        pageAction(
          span("New app"),
          "/adm/aws/codebuild/app/form"
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
