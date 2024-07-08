package com.swarm.pages.adm.stats

import com.raquo.laminar.api.L.*
import com.raquo.laminar.nodes.ReactiveHtmlElement
import com.swarm.api.ApiServer.ApiResult
import com.swarm.api.ApiStats
import com.swarm.models.{Stats, StatsItem}
import com.swarm.pages.comps.Theme.{breadcrumb, breadcrumbItem, pageAction, pageActions}
import com.swarm.util.ApiErrorHandle
import org.scalajs.dom.HTMLDivElement

import scala.concurrent.ExecutionContext.Implicits.global
import scala.util.Success

object StatsReportPage:

  private enum Sync:
    case Loading, Done

  private val message = Var[Option[String]](None)
  private val stat = Var[Option[Stats]](None)
  private val stats = Var[List[Stats]](Nil)
  private val items = Var[List[StatsItem]](Nil)
  private val sync = Var[Sync](Sync.Loading)

  def apply(id: Int): ReactiveHtmlElement[HTMLDivElement] =
    load(id)
    list()
    node()

  private def adjuste(data: List[StatsItem]): List[StatsItem] =
    data
      .sortBy(_.time * -1)
      .groupBy(_.text).map {
        (k, v) =>
          val t = v.foldRight((0, 0, 0)) {
            (value, acc) =>
              val min =
                if acc._1 == 0 || acc._1 > value.time
                then value.time
                else acc._1
              val max =
                if acc._2 < value.time
                then value.time
                else acc._2
              (min, max, acc._3 + value.time)
          }
          v.head.copy(
            min = t._1,
            max = t._2,
            avg = t._3 / v.length,
            total = t._3,
            count = v.length,
            items = v
          )
      }.toList

  private def load(id: Int) =
    ApiStats.get(id).onComplete:
      ApiErrorHandle.handle(message):
        case Success(ApiResult(Some(data), _, _, _)) =>
          stat.update(_ => Some(data))
          update()

  private def list() =
    ApiStats.list().onComplete:
      ApiErrorHandle.handle(message):
        case Success(ApiResult(Some(data), _, _, _)) =>
          stats.update(_ => data)

  private def update() =
    sync.update(_ => Sync.Loading)
    stat.now() match
      case Some(st) =>
        ApiStats.report(st.id).onComplete:
          ApiErrorHandle.handle(message):
            case Success(ApiResult(Some(data), _, _, _)) =>
              items.update(_ => adjuste(data))
              sync.update(_ => Sync.Done)


  private def defaultAction = pageAction(
    _ => update(),
    child <-- sync.signal.map {
      case Sync.Loading =>
        span(
          "sync",
          span(cls("fa fa-cog fa-spin fa-fw"))
        )
      case Sync.Done => span("sync")
    }
  )

  private def selectActions = stats.signal.map(_.map {
    st =>
      pageAction(
        _ => load(st.id),
        st.description
      )
  }).map(items => defaultAction :: items)

  private def actions() =
    pageActions(
      children <-- selectActions
    )

  private def tbRow(item: StatsItem) =
    tr(
      td(s"${item.count}x"),
      td(s"${item.min}ms"),
      td(s"${item.max}ms"),
      td(s"${item.avg}ms"),
      td(s"${item.total}ms"),
      td(
        span(s"${item.text}"),
        onDblClick --> { (_) =>
          items.update(data => data.mapConserve(x => if x.text == item.text then item.copy(showMore = !item.showMore) else x))
        } ,
        table(
          styleAttr(s"width: 100%; display: ${if item.showMore then "inline" else "none"}"),
          tbody(
            item.items.map {
              it => tr(td(small(s"> time: ${it.time}ms,  ${it.more}")))
            }
          )
        )
      )
    )

  private def node() =
    div(
      breadcrumb(
        breadcrumbItem(
          a(
            href("/adm/stats"),
            span(s"stats")
          ),
          false
        ),
        breadcrumbItem(
          label(
            child.maybe <-- stat.signal.map(_.map(_.description))
          ),
          true)
      ),
      actions(),
      child.maybe <-- message.signal.map(_.map(s => {
        div(
          cls("alert alert-danger"),
          span(s)
        )
      })),
      hr(),
      table(
        cls("table table-striped table-dark table-bordered table-hover table-sm table-adm"),
        thead(
          tr(
            List("count", "time min", "time max", "time avg", "total", "text").map(th(_))
          )
        ),
        tbody(
          children <-- items.signal.map(_.map(tbRow))
        )
      )

      // actions(),
    )
