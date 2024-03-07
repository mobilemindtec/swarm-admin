package com.swarm.pages.stacks

import com.raquo.laminar.api.L.*
import com.raquo.laminar.nodes.ReactiveHtmlElement
import com.swarm.api.ApiServer.ApiResult
import com.swarm.api.{ApiDockerStack, ApiStack}
import com.swarm.models.Stack
import com.swarm.pages.comps.LogLineView
import com.swarm.pages.comps.Theme.*
import com.swarm.util.ApiErrorHandle
import org.scalajs.dom.HTMLDivElement

import scala.concurrent.ExecutionContext.Implicits.global
import scala.util.{Failure, Success}

object StackManager:

  private val message = Var[Option[String]](None)
  private val stack = Var[Option[Stack]](None)
  private val results = Var[Option[List[String]]](Some("waiting by action.." :: Nil))

  def apply(id: String): ReactiveHtmlElement[HTMLDivElement] =
    load(id.toInt)
    node()

  private def load(id: Int) =
    ApiStack.get(id).onComplete {
      ApiErrorHandle.handle(message) { case Success(ApiResult(stk, _, _, _)) =>
        stack.update(_ => stk)
      }
    }

  private def exec(action: String) =
    message.set(None)
    results.set(Some(s"$$ $action..." :: Nil))

  private def rm(ev: Any): Unit =
    stack
      .now()
      .foreach { f =>
        exec(s"stack rm ${f.name}")
        ApiDockerStack.rm(f.name).onComplete {
          ApiErrorHandle.handle(message) { case Success(ApiResult(Some(cmd), _, _, _)) =>
            results.update(_ => cmd.messages)
          }
        }
      }

  private def deploy(ev: Any): Unit =
    stack
      .now()
      .foreach { f =>
        exec(s"stack deploy ${f.name}")
        ApiDockerStack.deploy(f.name).onComplete {
          ApiErrorHandle.handle(message) { case Success(ApiResult(Some(cmd), _, _, _)) =>
            results.update(_ => cmd.messages)
          }
        }
      }

  private def actions() =
    pageActions(
      pageAction(
        rm,
        child.maybe <-- stack.signal.map(_.map(s => span(s"stack rm ${s.name}")))
      ),
      pageAction(
        deploy,
        child.maybe <-- stack.signal.map(_.map(s => span(s"stack deploy ${s.name}")))
      )
    )

  private def node() =
    div(
      breadcrumb(
        breadcrumbItem(
          a(
            href("/adm/stack"),
            span("stacks")
          ),
          false
        ),
        breadcrumbItem(
          child.maybe <-- stack.signal.map(
            _.map(s => a(href(s"/adm/stack/form/${s.id}"), span(s"edit stack ${s.name}")))
          ),
          false
        ),
        breadcrumbItem(
          child.maybe <-- stack.signal.map(
            _.map(s => a(href("#"), span(s"stack manager #${s.id}")))
          ),
          true
        )
      ),
      actions(),
      child.maybe <-- message.signal.map(_.map(s => {
        div(
          cls("alert alert-danger"),
          span(s)
        )
      })),
      hr(),
      terminal(
        child.maybe <-- results.signal.map {
          for x <- _
          yield div(x.map(msg => LogLineView(msg).elem)*)
        }
      )
      // actions(),
    )
