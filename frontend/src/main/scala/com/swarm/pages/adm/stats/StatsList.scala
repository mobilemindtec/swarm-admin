package com.swarm.pages.adm.stats

import com.raquo.laminar.api.L.*
import com.raquo.laminar.nodes.ReactiveHtmlElement
import com.swarm.api.ApiServer.ApiResult
import com.swarm.api.ApiStats
import com.swarm.models.Stats
import com.swarm.pages.adm.stats.StatsForm.message
import com.swarm.pages.comps.Theme.{breadcrumb, breadcrumbItem, pageAction, pageActions}
import com.swarm.services.Router
import com.swarm.util.ApiErrorHandle
import org.scalajs.dom.{HTMLDivElement, window}

import scala.concurrent.ExecutionContext.Implicits.global
import scala.util.{Failure, Success}

object StatsList:

  private val message = Var[Option[String]](None)
  private val stats = Var(List[Stats]())

  def apply(): ReactiveHtmlElement[HTMLDivElement] = node()

  def mount() =
    load()
  private def load() =
    ApiStats.list().onComplete {
      ApiErrorHandle.handle(message) { case Success(ApiResult(Some(lst), _, _, _)) =>
        stats.update(_ => lst)
      }
    }
  private def remove(stat: Stats) =
    if window.confirm("Are you sure?") then
      ApiStats.delete(stat).onComplete {
        ApiErrorHandle.handleUnit(message) { case Success(_) =>
          stats.update(lst => lst.filterNot(_.id == stat.id))
        }
      }

  private def edit(stat: Stats) =
    Router.navigate(s"/adm/stats/form/${stat.id}")

  private def report(stat: Stats) =
    Router.navigate(s"/adm/stats/report/${stat.id}")

  private def header =
    breadcrumb(
      breadcrumbItem(
        "stats",
        true
      )
    )

  private def tbRow(stats: Stats) =
    tr(
      td(stats.id.toString),
      td(stats.description),
      td(stats.awsS3Uri),
      td(stats.updatedAt),
      td(
        cls("text-center"),
        a(
          href(s"/adm/stats/report/${stats.id}"),
          i(cls("fa fa-list")),
          title("Open"),
          onClick --> (_ => report(stats))
        )
      ),
      td(
        cls("text-center"),
        a(
          href(s"/adm/stats/form/${stats.id}"),
          i(cls("fa fa-edit")),
          title("edit"),
          onClick --> (_ => edit(stats))
        )
      ),
      td(
        cls("text-center"),
        a(
          href("#"),
          i(cls("fa fa-trash")),
          title("remove"),
          onClick --> (_ => remove(stats))
        )
      )
    )

  private def tb() =
    table(
      cls("table table-striped table-dark table-bordered table-hover table-sm table-adm"),
      thead(
        tr(
          List("#", "description", "aws s3 uri", "last update", "", "", "").map { s =>
            th(s)
          }
        )
      ),
      tbody(
        children <-- stats.signal.map(_.map(tbRow))
      )
    )
  private def node() =
    div(
      onMountCallback(_ => mount()),
      header,
      pageActions(
        pageAction(
          span("New Stats"),
          "/adm/stats/form"
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
