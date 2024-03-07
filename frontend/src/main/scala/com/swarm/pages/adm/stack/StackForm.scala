package com.swarm.pages.adm.stack

import com.raquo.laminar.api.L.*
import com.raquo.laminar.receivers.ChildReceiver.text
import com.swarm.api.ApiServer.ApiResult
import com.swarm.api.ApiStack
import com.swarm.facade.{Editor, EditorOpts}
import com.swarm.models.Stack
import com.swarm.pages.adm.aws.codebuild.app.AwsCodeBuildAppList.message
import com.swarm.pages.comps.Theme.{breadcrumb, breadcrumbItem}
import com.swarm.services.Router
import com.swarm.util.ApiErrorHandle
import org.scalajs.dom
import org.scalajs.dom.{document, window}
import io.scalaland.chimney.dsl.*

import scala.concurrent.ExecutionContext.Implicits.global
import scala.util.{Failure, Success}
object StackForm:

  final case class StackForm(
    id: Int = 0,
    name: String = "",
    content: String = "",
    enabled: Boolean = true
  ):
    def validate: Boolean = this.content.nonEmpty && this.name.nonEmpty

  private val message = Var[Option[String]](None)
  private val stateVar = Var(StackForm())

  private val editor = Editor()

  private def header =
    breadcrumb(
      breadcrumbItem(
        a(
          href("/adm/stack"),
          span(s"stacks")
        ),
        false
      ),
      breadcrumbItem(
        "stack",
        true
      )
    )

  def apply(id: Int) =
    load(id)
    node()
  def apply() = node()

  private def mount() =
    val el = document.getElementById("stackContent")
    editor.render(el)
  private def unmount() =
    println("unmount")

  private def formSubmitter = Observer[StackForm] { state =>
    if !state.validate then message.update(_ => Some("Enter with name and content"))
    else submit(state)
  }
  private def submit(form: StackForm) =
    val stack = form
      .into[Stack]
      .withFieldComputed(_.updatedAt, _ => "")
      .transform
    (if form.id == 0
     then ApiStack.save(stack)
     else ApiStack.update(stack)).onComplete {
      ApiErrorHandle.handle(message) { case Success(_) =>
        Router.navigate("/adm/stack")
      }
    }

  private def load(id: Int) =
    ApiStack.get(id).onComplete {
      ApiErrorHandle.handle(message) { case Success(ApiResult(Some(stack), _, _, _)) =>
        val form = stack.into[StackForm].transform
        stateVar.set(form)
        editor.codemirror.setValue(form.content)
      }
    }

  private def node() =
    div(
      header,
      div(
        onMountCallback(_ => mount()),
        onUnmountCallback(_ => unmount()),
        cls("col-md-8 offset-2 col-12 mt-5"),
        h2(
          cls("text-center"),
          "Stack"
        ),
        hr(),
        form(
          div(
            cls("form-group"),
            label("Stack Name"),
            input(
              cls("form-control"),
              placeholder("my-stack"),
              onInput.mapToValue --> stateVar.updater[String]((state, s) => state.copy(name = s)),
              value <-- stateVar.signal.map(_.name)
            )
          ),
          div(
            cls("form-group"),
            label("Stack Content"),
            textArea(
              idAttr("stackContent"),
              cls("form-control")
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
          onSubmit.preventDefault.mapTo(updateContent().now()) --> formSubmitter
        )
      )
    )

  private def updateContent(): Var[StackForm] =
    stateVar.update(state => state.copy(content = editor.codemirror.getValue()))
    stateVar
