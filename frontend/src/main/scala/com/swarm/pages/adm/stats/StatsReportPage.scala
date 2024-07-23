package com.swarm.pages.adm.stats

import com.raquo.laminar.api.L.*
import com.raquo.laminar.nodes.ReactiveHtmlElement
import com.swarm.api.ApiServer.ApiResult
import com.swarm.api.ApiStats
import com.swarm.charts.google.{charts, visualization}
import com.swarm.models.{LineChartData, PieChartData, Stats, StatsItem}
import com.swarm.pages.comps.Theme.{breadcrumb, breadcrumbItem, pageAction, pageActions}
import com.swarm.util.ApiErrorHandle
import moment.Moment
import org.scalajs.dom.{HTMLDivElement, document, window}


import scala.concurrent.ExecutionContext.Implicits.global
import scala.scalajs.js.Date
import scala.util.Success
import scala.scalajs.js
import js.JSConverters.*



object StatsReportPage:

  private enum Sync:
    case Loading, Done

  private val message = Var[Option[String]](None)
  private val stat = Var[Option[Stats]](None)
  private val stats = Var[List[Stats]](Nil)
  private val items = Var[List[StatsItem]](Nil)
  private val sync = Var[Sync](Sync.Loading)
  private val lineChartData = Var[List[LineChartData]](Nil)
  private val pieChartData = Var[List[PieChartData]](Nil)

  def apply(id: Int): ReactiveHtmlElement[HTMLDivElement] =
    load(id)
    list()
    node()

  private def adjuste(data: List[StatsItem]): List[StatsItem] =
    data
      .groupBy(_.text).map {
        (k, v) =>
          val t = v.foldRight((0D, 0D, 0D)) {
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
      }
      .toList
      .sortBy(_.max * -1)

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
        st.typ match
          case "table" =>
            loadReportTable(st.id)
          case "line_chart"  =>
            loadReportLineChart(st.id)
          case "pie_chart"=>
            loadReportPieChart(st.id)

    ()

  private def loadReportLineChart(id: Int) =
    ApiStats.lineChart(id).onComplete:
      ApiErrorHandle.handle(message):
        case Success(ApiResult(Some(data), _, _, _)) =>
          lineChartData.update(_ => data)
          sync.update(_ => Sync.Done)
          drawLineChart()

  private def loadReportPieChart(id: Int) =
    ApiStats.pieChart(id).onComplete:
      ApiErrorHandle.handle(message):
        case Success(ApiResult(Some(data), _, _, _)) =>
          pieChartData.update(_ => data)
          sync.update(_ => Sync.Done)
          drawPieChart()

  private def loadReportTable(id: Int) =
    ApiStats.report(id).onComplete:
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
      child.maybe <-- stat.signal.map(_.map { s =>
        s.typ match
          case "table" => renderTable()
          case "line_chart" => renderLineChart()
          case "pie_chart" => renderPieChart()
      }),
      // actions(),
    )

  private def renderTable() =
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

  private def renderLineChart() =
    div(
      idAttr("chart"),
    )

  private def renderPieChart() =
    div(
      children <-- pieChartData.signal.map(_.map(s => div(idAttr(s.id))))
    )

  private def drawLineChart() =
    val lines = lineChartData.now()
    val st = stat.now().get
    val arrs = js.Array[js.Array[js.Any]]()

    val labels = lines.groupBy(_.label)
    val max = lines.headOption.map(_.total).getOrElse(0)

    val headers = js.Array[js.Any]("Datetime")
    for label <- labels.keys do
      headers.append(label)

    arrs.append(headers)

    for (k, v) <- lines.groupBy(_.timestamp) do
      //window.console.log(k, v.head.date)
      val a = js.Array[js.Any](v.head.date)
      for label <- labels.keys do
        v.find(_.label == label) match
          case Some(i) => a.append(i.value)
          case None => a.append(0)
      arrs.append(a)

    charts.load(
      "current",
      js.Dynamic.literal("packages" -> js.Array("corechart")))

    val f = () => {
      val data = visualization.arrayToDataTable(
      arrs
      )
      val options = js.Dynamic.literal(
        "title" -> st.description,
        "curveType" -> "function",
        "legend" -> js.Dynamic.literal("position" -> "right"),
        "vAxis" -> js.Dynamic.literal("maxValue" -> 250, "minValue" -> 0)
      )
      val chart = new visualization.LineChart(document.getElementById("chart"))
      chart.draw(data, options)
    }

    charts.setOnLoadCallback (f)

  private def drawPieChart() =
    window.console.log("drawPieChart")
    val lines = pieChartData.now()
    val st = stat.now().get

    charts.load(
      "current",
      js.Dynamic.literal("packages" -> js.Array("corechart")))

    val f = () => {

      for line <- lines do
        val arrs = js.Array[js.Array[js.Any]]()
        arrs.append(js.Array[js.Any](line.label, "value"))
        arrs.append(js.Array[js.Any]("Available", line.total-line.value))
        arrs.append(js.Array[js.Any]("Used", line.value))

        val data = visualization.arrayToDataTable(
          arrs
        )
        val options = js.Dynamic.literal(
          "title" -> s"${st.description} - ${line.label}",
         // "legend" -> js.Dynamic.literal("position" -> "right"),
        )
        val chart = new visualization.PieChart(document.getElementById(line.id))
        chart.draw(data, options)
    }

    charts.setOnLoadCallback(f)