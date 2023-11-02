package com.swarm.pages.adm.stack

import com.raquo.laminar.api.L.*
import com.raquo.laminar.nodes.ReactiveHtmlElement
import com.swarm.api.ApiStack
import com.swarm.models.Models.Stack
import com.swarm.pages.comps.Theme.{breadcrumb, breadcrumbItem, pageAction, pageActions}
import com.swarm.services.Router
import org.scalajs.dom.{HTMLDivElement, window}

import scala.concurrent.ExecutionContext.Implicits.global
import scala.util.{Failure, Success}

object StackList:

  private val message = Var[Option[String]](None)
  private val stacks = Var(List[Stack]())

  def apply(): ReactiveHtmlElement[HTMLDivElement] = node()

  def mount() =
    load()
  private def load() =
    ApiStack.list().onComplete {
      case Success(result) =>
        stacks.update(_ => result.data)
      case Failure(err) => message.update(_ => Some(s"${err.getMessage}"))
    }
  private def remove(stack: Stack) =
    if window.confirm("Are you sure?") then
      ApiStack.delete(stack).onComplete {
        case Success(_) =>
          stacks.update(lst => lst.filterNot(_.id == stack.id))
        case Failure(err) => message.update(_ => Some(s"${err.getMessage}"))
      }

  private def edit(stack: Stack) =
    Router.navigate(s"/adm/stack/form/${stack.id}")

  private def mgr(stack: Stack) =
    Router.navigate(s"/docker/stack/mgr/${stack.id}")

  private def header =
    breadcrumb(
      breadcrumbItem(
        a(
          href("#"),
          span(s"stacks")
        ),
        true
      )
    )

  private def tbRow(stack: Stack) =
    tr(
      td(stack.id.toString),
      td(stack.name),
      td(stack.updatedAt),
      td(
        cls("text-center"),
        a(
          href("#"),
          i(cls("fa fa-cubes")),
          title("stack manager"),
          onClick --> (_ => mgr(stack))
        )
      ),
      td(
        cls("text-center"),
        a(
          href(s"/adm/stack/form/${stack.id}"),
          i(cls("fa fa-edit")),
          title("edit"),
          onClick --> (_ => edit(stack))
        )
      ),
      td(
        cls("text-center"),
        a(
          href("#"),
          i(cls("fa fa-trash")),
          title("remove"),
          onClick --> (_ => remove(stack))
        )
      )
    )

  private def tb() =
    table(
      cls("table table-striped table-dark table-bordered table-hover table-sm table-adm"),
      thead(
        tr(
          List("#", "name", "last update", "", "", "").map { s =>
            th(s)
          }
        )
      ),
      tbody(
        children <-- stacks.signal.map(_.map(tbRow))
      )
    )
  private def node() =
    div(
      onMountCallback(_ => mount()),
      header,
      pageActions(
        pageAction(
          span("New Stack"),
          "/adm/stack/form"
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
