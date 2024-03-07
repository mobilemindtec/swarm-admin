package com.swarm.pages.adm.aws.codebuild.build

import com.raquo.laminar.api.L.*
import com.raquo.laminar.nodes.ReactiveHtmlElement
import com.swarm.api.{ApiAwsBuild, ApiAwsCodeBuildApp}
import com.swarm.api.ApiServer.ApiResult
import com.swarm.api.WebSocketClient.{WsClient, WsMsg, WsMsgType}
import com.swarm.models.{AwsBuild, AwsCodeBuildApp}
import com.swarm.pages.comps.LogLineView
import com.swarm.pages.comps.Theme.{breadcrumb, breadcrumbItem, terminal}
import com.swarm.util.ApiErrorHandle
import org.getshaka.nativeconverter.NativeConverter
import org.scalajs.dom.HTMLDivElement

import scala.concurrent.ExecutionContext.Implicits.global
import scala.scalajs.js
import scala.scalajs.js.Date
import scala.util.{Failure, Success}

object AwsBuildLogStream:

  private val message = Var[Option[String]](None)
  private val wsClient = WsClient()
  private val awsApp = Var[Option[AwsCodeBuildApp]](None)
  private val awsBuild = Var[Option[AwsBuild]](None)

  def apply(id: String): ReactiveHtmlElement[HTMLDivElement] =
    print("AwsBuildLogStream")
    load(id)
    node()

  private def loadAwsApp(id: Int): Unit =
    ApiAwsCodeBuildApp.get(id).onComplete {
      ApiErrorHandle.handle(message) { case Success(ApiResult(app, _, _, _)) =>
        awsApp.update(_ => app)
      }
    }

  private def load(id: String) =
    ApiAwsBuild.get(id.toInt).onComplete {
      ApiErrorHandle.handle(message) { case Success(ApiResult(build, _, _, _)) =>
        awsBuild.update(_ => build)
        build.foreach { b =>
          streamOpen(b)
          loadAwsApp(b.awsCodebuildAppId)
        }
      }
    }

  private def streamOpen(build: AwsBuild) =
    wsClient.open().onComplete {
      ApiErrorHandle.handleUnit(message) { case Success(_) =>
        val msg = WsMsg(WsMsgType.awsLogsStreamStart.toString, build.toNative)
        wsClient.send(msg)
      }
    }

  private def unmount(): Unit =
    wsClient.close()

  private def node() =
    div(
      onUnmountCallback(_ => unmount()),
      breadcrumb(
        breadcrumbItem(
          a(
            href("/adm/aws/codebuild/app"),
            span("aws codebuild apps")
          ),
          false
        ),
        breadcrumbItem(
          child.maybe <-- awsApp.signal.map(
            _.map(app =>
              a(
                href(s"/adm/aws/build/${app.id}"),
                span(s"aws builds for ${app.awsProjectName} ")
              )
            )
          ),
          false
        ),
        breadcrumbItem(
          child.maybe <-- awsBuild.signal.map(
            _.map(build => span(s"aws log build for ${build.buildId} "))
          ),
          true
        )
      ),
      child.maybe <-- message.signal.map(_.map(s => {
        div(
          cls("alert alert-danger"),
          span(s)
        )
      })),
      hr(),
      child.maybe <-- awsBuild.signal.map(
        _.map(build =>
          a(href(build.logsDeepLink), target("_blank"), s"deep link ${build.logsDeepLink}")
        )
      ),
      hr(),
      terminal(
        // onMountCallback(_ => mount(serviceName, serviceId)),
        children.command <-- wsClient.buss.events.map(msg => LogLineView(msg)).map(_.node)
      )
      // actions(),
    )
