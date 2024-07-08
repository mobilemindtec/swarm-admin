package com.swarm.pages.adm.stats

import com.raquo.laminar.api.L.*
import com.raquo.laminar.receivers.ChildReceiver.text
import com.swarm.api.ApiServer.ApiResult
import com.swarm.api.ApiStats
import com.swarm.facade.{Editor, EditorOpts}
import com.swarm.models.Stats
import com.swarm.pages.adm.aws.codebuild.app.AwsCodeBuildAppList.message
import com.swarm.pages.comps.Theme.{breadcrumb, breadcrumbItem}
import com.swarm.services.Router
import com.swarm.util.ApiErrorHandle
import org.scalajs.dom
import org.scalajs.dom.{document, window}
import io.scalaland.chimney.dsl.*

import scala.concurrent.ExecutionContext.Implicits.global
import scala.util.{Failure, Success}
object StatsForm:

  final case class StatsForm(
    id: Int = 0,
    description: String = "",
    awsS3Uri: String = ""
  ):
    def validate: Boolean = this.description.nonEmpty && this.awsS3Uri.nonEmpty

  private val message = Var[Option[String]](None)
  private val stateVar = Var(StatsForm())

  private def header =
    breadcrumb(
      breadcrumbItem(
        a(
          href("/adm/stats"),
          span(s"stats")
        ),
        false
      ),
      breadcrumbItem(
        "stats",
        true
      )
    )

  def apply(id: Int) =
    load(id)
    node()
  def apply() = node()

  private def formSubmitter = Observer[StatsForm] { state =>
    if !state.validate then message.update(_ => Some("Enter with name and content"))
    else submit(state)
  }
  private def submit(form: StatsForm) =
    val stats = form
      .into[Stats]
      .withFieldComputed(_.updatedAt, _ => "")
      .transform
    (if form.id == 0
     then ApiStats.save(stats)
     else ApiStats.update(stats)).onComplete {
      ApiErrorHandle.handle(message) { case Success(_) =>
        Router.navigate("/adm/stats")
      }
    }

  private def load(id: Int) =
    ApiStats.get(id).onComplete {
      ApiErrorHandle.handle(message) { case Success(ApiResult(Some(stats), _, _, _)) =>
        val form = stats.into[StatsForm].transform
        stateVar.set(form)
      }
    }

  private def node() =
    div(
      header,
      div(
        cls("col-md-8 offset-2 col-12 mt-5"),
        h2(
          cls("text-center"),
          "Stats"
        ),
        hr(),
        form(
          div(
            cls("form-group"),
            label("Description"),
            input(
              cls("form-control"),
              placeholder("my stats report"),
              onInput.mapToValue --> stateVar.updater[String]((state, s) =>
                state.copy(description = s)
              ),
              value <-- stateVar.signal.map(_.description)
            )
          ),
          div(
            cls("form-group"),
            label("AWS S3 Uri"),
            input(
              cls("form-control"),
              placeholder("s3://bucket/stats/logs.json"),
              onInput.mapToValue --> stateVar.updater[String]((state, s) =>
                state.copy(awsS3Uri = s)
              ),
              value <-- stateVar.signal.map(_.awsS3Uri)
            )
          ),
          child.maybe <-- message.signal.map(_.map(s => {
            div(
              cls("alert alert-danger"),
              span(s)
            )
          })),
          hr(),
          div(
            button(
              "SAVE",
              typ("submit")
            )
          ),
          onSubmit.preventDefault.mapTo(stateVar.now()) --> formSubmitter
        )
      )
    )
