package com.swarm.pages.services

import com.raquo.laminar.api.L.*
import com.swarm.api.ApiDockerService
import com.swarm.api.ApiServer.ApiResult
import com.swarm.models.{CmdResult, Service}
import com.swarm.pages.adm.stack.StackForm.message
import com.swarm.pages.comps.Theme.*
import com.swarm.util.ApiErrorHandle

import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.Future
import scala.scalajs.js
import scala.util.{Failure, Success, Try}

enum TerminalView:
  case Table
  case Cmd(cmdList: List[CmdLine])

object ServicePS:

  private val servicesVar = Var[Option[List[Service]]](None)
  private val terminalViewVar = Var(TerminalView.Table)
  private val service = Var[(String, String)](("", ""))
  private val message = Var[Option[String]](None)

  def apply(id: String) =
    service.update(_ => ("", id))
    node(id)

  private def dockerServiceRm(ev: Any): Unit =
    val (name, _) = service.now()
    val cmd = s"docker service rm ${name}"
    terminalViewVar.update(_ => TerminalView.Cmd(CmdLine(cmd, CmdType.Loading) :: Nil))
    ApiDockerService.rm(name).onComplete(cmdExecuteResult(cmd))

  private def dockerServiceUpdate(ev: Any): Unit =
    val (name, _) = service.now()
    val cmd = s"docker service update ${name} --force"
    terminalViewVar.update(_ => TerminalView.Cmd(CmdLine(cmd, CmdType.Loading) :: Nil))
    ApiDockerService.update(name).onComplete(cmdExecuteResult(cmd))

  private def dockerServiceLogsGet(ev: Any): Unit =
    val (name, _) = service.now()
    val cmd = s"docker service logs $name"
    terminalViewVar.update(_ => TerminalView.Cmd(CmdLine(cmd, CmdType.Loading) :: Nil))
    ApiDockerService.logs(name).onComplete(cmdExecuteResult(cmd))

  private def cmdExecuteResult(cmd: String)(r: Try[ApiResult[CmdResult]]): Unit =
    val lines = r match
      case Success(ApiResult(Some(CmdResult(error, message)), _, _, _)) =>
        if error.getOrElse(false)
        then message.getOrElse("unknown error" :: Nil).map(s => CmdLine(s, CmdType.Error))
        else message.getOrElse("unknow result" :: Nil).map(s => CmdLine(s, CmdType.Done))
      case Success(ApiResult(_, Some(true), error, errors)) =>
        CmdLine(
          error.orElse(errors.map(_.mkString(", "))).getOrElse("unknown error"),
          CmdType.Error
        ) :: Nil
      case Success(_) =>
        CmdLine("unknown error", CmdType.Error) :: Nil
      case Failure(exception) =>
        CmdLine(exception.getMessage, CmdType.Error) :: Nil

    terminalViewVar.update(_ => TerminalView.Cmd(CmdLine(cmd, CmdType.Done) :: lines))

  private def extractServiceName(services: List[Service]): Unit =
    if services.nonEmpty
    then service.update(s => (services.head.serviceName, s._2))

  private def apiSync(id: String): Unit =
    ApiDockerService.ps(id).onComplete {
      ApiErrorHandle.handle(message) { case Success(data) =>
        data.data.foreach(extractServiceName)
        servicesVar.update(_ => data.data)
      }
    }
  private def mount(id: String) = apiSync(id)

  private def unmount() =
    terminalViewVar.update(_ => TerminalView.Table)
    servicesVar.update(_ => None)
    service.update(_ => ("", ""))

  private def actions() =
    pageActions(
      pageAction(
        dockerServiceRm,
        span("service rm")
      ),
      pageAction(
        dockerServiceUpdate,
        span("service update")
      ),
      pageAction(
        dockerServiceLogsGet,
        span("logs get")
      ),
      pageAction(
        span("log stream"),
        service.signal.map((name, id) => s"/docker/service/log/stream/$name/$id")
      )
    )

  private def node(id: String) =
    div(
      onUnmountCallback(_ => unmount()),
      breadcrumb(
        breadcrumbItem(
          a(
            href("#"),
            span(child <-- service.signal.map((name, _) => s"docker service ps $name")),
            onClick --> (_ => terminalViewVar.update(_ => TerminalView.Table))
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
      child <-- terminalViewVar.signal.map {
        case TerminalView.Table     => terminal(tb(id))
        case TerminalView.Cmd(cmds) => terminal(command(cmds*))
      }
    )

  private def tbr(service: Service) =
    tr(
      td(
        dataAttr("title")("ID"),
        service.id
      ),
      td(
        dataAttr("title")("NAME"),
        service.name
      ),
      td(
        dataAttr("title")("IMAGE"),
        service.image.map(x => if x.length > 30 then x.substring(0, 30) else x).getOrElse("-")
      ),
      td(
        dataAttr("title")("NODE"),
        service.node.getOrElse("-")
      ),
      td(
        dataAttr("title")("STATE"),
        service.currentState.getOrElse("-")
      ),
      td(
        dataAttr("title")("ERROR"),
        service.err.filter(_.nonEmpty).getOrElse("-")
      )
    )
  private def tb(id: String) =
    table(
      onMountCallback(_ => mount(id)),
      styleAttr("width: 100%; min-width: 100%"),
      thead(
        tr(
          List("ID", "NAME", "IMAGE", "NODE", "STATE", "ERROR").map(c => th(c))
        )
      ),
      tbody(
        children <-- servicesVar.signal.map(_.map(_.map(tbr)).getOrElse(List()))
      )
    )
