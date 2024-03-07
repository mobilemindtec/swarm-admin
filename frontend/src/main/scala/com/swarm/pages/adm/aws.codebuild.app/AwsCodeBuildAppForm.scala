package com.swarm.pages.adm.aws.codebuild.app

import com.raquo.laminar.api.L.*
import com.swarm.api.ApiServer.ApiResult
import com.swarm.api.{ApiAwsCodeBuildApp, ApiStack}
import com.swarm.models.AwsCodeBuildApp
import com.swarm.pages.comps.Theme.{breadcrumb, breadcrumbItem}
import com.swarm.util.ApiErrorHandle
import frontroute.BrowserNavigation
import io.scalaland.chimney.dsl.*
import org.scalajs.dom
import org.scalajs.dom.{HTMLLabelElement, window}

import scala.concurrent.ExecutionContext.Implicits.global
import scala.util.{Failure, Success}
object AwsCodeBuildAppForm:

  case class StackOption(id: Int, text: String, selected: Boolean)
  final case class AwsCodeBuildAppForm(
    id: Int = 0,
    stackVarName: String = "",
    versionTag: String = "",
    awsEcrRepositoryName: String = "",
    awsAccountId: String = "",
    awsRegion: String = "",
    awsUrl: String = "",
    awsProjectName: String = "",
    codeBase: String = "",
    buildVars: String = "",
    stackId: Int = 0,
    updatedAt: String = ""
  ):
    def validate: Boolean =
      stackId > 0 && validateStrings
    private def validateStrings =
      !Seq[String](
        stackVarName,
        versionTag,
        awsEcrRepositoryName,
        awsAccountId,
        awsRegion,
        awsUrl,
        awsProjectName,
        codeBase,
        buildVars
      ).exists(_.trim.isEmpty)

  private val message = Var[Option[String]](None)
  private val stateVar = Var(AwsCodeBuildAppForm())
  private val stackOptions = Var[List[StackOption]](StackOption(0, "Select..", false) :: Nil)

  def apply(id: Int) =
    load(id)
    node()
  def apply() =
    clear()
    loadStaks()
    node()

  private def mount() =
    ()

  private def unmount() =
    ()

  private def formSubmitter = Observer[AwsCodeBuildAppForm] { state =>
    if !state.validate then message.update(_ => Some("Enter with all required fields"))
    else submit(state)
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
        "aws codebuild app",
        true
      )
    )
  private def clear() =
    stateVar.set(AwsCodeBuildAppForm())
  private def goback(): Unit =
    clear()
    BrowserNavigation.replaceState(
      url = "/adm/aws/codebuild/app"
    )

  private def onClone(): Unit =
    if window.confirm("Are you sure?") then
      ApiAwsCodeBuildApp.clone(stateVar.now().id).onComplete {
        ApiErrorHandle.handle(message) { case Success(ApiResult(Some(app), _, _, _)) =>
          BrowserNavigation.replaceState(
            url = s"/adm/aws/codebuild/app/form/${app.id}"
          )
        }
      }

  private def submit(form: AwsCodeBuildAppForm) =
    val stack = form
      .into[AwsCodeBuildApp]
      .withFieldComputed(_.updatedAt, _ => "")
      .withFieldComputed(_.lastBuildAt, _ => "")
      .withFieldComputed(_.building, _ => false)
      .transform
    (if form.id == 0
     then ApiAwsCodeBuildApp.save(stack)
     else ApiAwsCodeBuildApp.update(stack)).onComplete {
      ApiErrorHandle.handleUnit(message) { case Success(_) =>
        goback()
      }
    }

  private def load(id: Int) =
    ApiAwsCodeBuildApp.get(id).onComplete {
      ApiErrorHandle.handle(message) { case Success(ApiResult(Some(app), _, _, _)) =>
        val form = app.into[AwsCodeBuildAppForm].transform
        stateVar.set(form)
        loadStaks(form.stackId)

      }
    }

  private def loadStaks(stackId: Int = 0) =
    ApiStack.list().onComplete {
      ApiErrorHandle.handle(message) { case Success(ApiResult(Some(apps), _, _, _)) =>
        stackOptions.update { items =>
          items ::: apps.map(s => StackOption(s.id, s.name, stackId == s.id))
        }
      }
    }
  private def rowInput[Ref <: dom.html.Element](
    lbl: String,
    plholder: String,
    reader: Signal[String],
    writer: Observer[String]
  ) =
    div(
      cls("col-md-4 col-12"),
      div(
        cls("form-group"),
        label(lbl),
        input(
          cls("form-control"),
          placeholder(plholder),
          controlled(
            onInput.mapToValue --> writer,
            value <-- reader
          )
        )
      )
    )
  private def node() =
    div(
      header,
      div(
        onMountCallback(_ => mount()),
        onUnmountCallback(_ => unmount()),
        cls("col-md-8 offset-2 col-12 mt-5 form"),
        h2(
          cls("text-center"),
          "AWS CodeBuild App"
        ),
        hr(),
        form(
          div(
            cls("row"),
            rowInput(
              lbl = "Stack var name",
              plholder = "APP_NAME_VERSION",
              reader = stateVar.signal.map(_.stackVarName),
              writer = stateVar.updater[String]((state, s) => state.copy(stackVarName = s))
            ),
            rowInput(
              lbl = "Version",
              plholder = "1.0",
              reader = stateVar.signal.map(_.versionTag),
              writer = stateVar.updater[String]((state, s) => state.copy(versionTag = s))
            ),
            rowInput(
              lbl = "Code base",
              plholder = "app/folder",
              reader = stateVar.signal.map(_.codeBase),
              writer = stateVar.updater[String]((state, s) => state.copy(codeBase = s))
            ),
            rowInput(
              lbl = "AWS ECR repository name",
              plholder = "app_repo",
              reader = stateVar.signal.map(_.awsEcrRepositoryName),
              writer = stateVar.updater[String]((state, s) => state.copy(awsEcrRepositoryName = s))
            ),
            rowInput(
              lbl = "AWS Build Name",
              plholder = "app_build_name",
              reader = stateVar.signal.map(_.awsProjectName),
              writer = stateVar.updater[String]((state, s) => state.copy(awsProjectName = s))
            ),
            rowInput(
              lbl = "AWS Account ID",
              plholder = "...",
              reader = stateVar.signal.map(_.awsAccountId),
              writer = stateVar.updater[String]((state, s) => state.copy(awsAccountId = s))
            ),
            rowInput(
              lbl = "AWS Region",
              plholder = "us-east-1",
              reader = stateVar.signal.map(_.awsRegion),
              writer = stateVar.updater[String]((state, s) => state.copy(awsRegion = s))
            )
          ),
          div(
            cls("form-group"),
            label("Stack"),
            select(
              cls("form-control"),
              children <-- stackOptions.signal.map(_.map { opt =>
                option(
                  value(opt.id.toString),
                  selected(opt.selected),
                  opt.text
                )
              }),
              onChange.mapToValue --> stateVar.updater[String]((state, s) =>
                state.copy(stackId = s.toInt)
              )
            )
          ),
          div(
            cls("form-group"),
            label("Build vars"),
            input(
              cls("form-control"),
              placeholder("VAR=1,VAR2=2"),
              onInput.mapToValue --> stateVar.updater[String]((state, s) =>
                state.copy(buildVars = s)
              ),
              value <-- stateVar.signal.map(_.buildVars)
            )
          ),
          div(
            cls("form-group"),
            label("AWS URL"),
            input(
              cls("form-control"),
              placeholder("https://us-east-1.console.aws.amazon.com"),
              onInput.mapToValue --> stateVar.updater[String]((state, s) => state.copy(awsUrl = s)),
              value <-- stateVar.signal.map(_.awsUrl)
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
            ),
            button(
              "CANCEL",
              onClick --> (_ => goback())
            ),
            button(
              "CLONE",
              cls("pull-left"),
              onClick --> (_ => onClone())
            )
          ),
          onSubmit.preventDefault.mapTo(stateVar.now()) --> formSubmitter
        )
      )
    )
