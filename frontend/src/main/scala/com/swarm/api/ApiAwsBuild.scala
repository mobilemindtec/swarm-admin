package com.swarm.api

import com.swarm.api.ApiServer.{ApiResult, defaultHeaders, fetch}
import com.swarm.configs.AppConfigs
import com.swarm.models.{AwsBuild, AwsCodeBuildApp}
import org.getshaka.nativeconverter.NativeConverter

import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.Future
import scala.scalajs.js.Dynamic

object ApiAwsBuild:

  def list(app: AwsCodeBuildApp): Future[ApiResult[List[AwsBuild]]] =
    val url = s"${AppConfigs.serverUrl}/api/aws/build/list/${app.id}"
    fetch(url, "GET", None, defaultHeaders)
      .map(r => NativeConverter[ApiResult[List[AwsBuild]]].fromNative(r))
  def update(awsBuild: AwsBuild): Future[ApiResult[AwsBuild]] =
    val url = s"${AppConfigs.serverUrl}/api/aws/build"
    val body = Dynamic.literal("id" -> awsBuild.id)
    fetch(url, "PUT", Some(body), defaultHeaders)
      .map(r => NativeConverter[ApiResult[AwsBuild]].fromNative(r))
  def delete(awsBuild: AwsBuild): Future[Unit] =
    val url = s"${AppConfigs.serverUrl}/api/aws/build"
    val body = Dynamic.literal("id" -> awsBuild.id)
    fetch(url, "DELETE", Some(body), defaultHeaders)
      .map(_ => ())
  def get(id: Int): Future[ApiResult[AwsBuild]] =
    val url = s"${AppConfigs.serverUrl}/api/aws/build/$id"
    fetch(url, "GET", None, defaultHeaders)
      .map(r => NativeConverter[ApiResult[AwsBuild]].fromNative(r))
  def start(app: AwsCodeBuildApp): Future[ApiResult[AwsBuild]] =
    val url = s"${AppConfigs.serverUrl}/api/aws/build/start/${app.id}"
    fetch(url, "GET", None, defaultHeaders)
      .map(r => NativeConverter[ApiResult[AwsBuild]].fromNative(r))
  def stop(awsBuild: AwsBuild): Future[ApiResult[AwsBuild]] =
    val url = s"${AppConfigs.serverUrl}/api/aws/build/stop/${awsBuild.id}"
    fetch(url, "GET", None, defaultHeaders)
      .map(r => NativeConverter[ApiResult[AwsBuild]].fromNative(r))
