package com.swarm.api

import com.swarm.api.ApiServer.{ApiResult, defaultHeaders, fetch}
import com.swarm.configs.AppConfigs
import com.swarm.models.Models.AwsCodeBuildApp
import org.getshaka.nativeconverter.NativeConverter

import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.Future
import scala.scalajs.js.Dynamic

object ApiAwsCodeBuildApp:

  def list(): Future[ApiResult[List[AwsCodeBuildApp]]] =
    val url = s"${AppConfigs.serverUrl}/api/aws/codebuild/app"
    fetch(url, "GET", None, defaultHeaders)
      .map(r => NativeConverter[ApiResult[List[AwsCodeBuildApp]]].fromNative(r))

  def save(awsApp: AwsCodeBuildApp): Future[ApiResult[AwsCodeBuildApp]] =
    val url = s"${AppConfigs.serverUrl}/api/aws/codebuild/app"
    fetch(url, "POST", Some(awsApp.toNative), defaultHeaders)
      .map(r => NativeConverter[ApiResult[AwsCodeBuildApp]].fromNative(r))

  def update(awsApp: AwsCodeBuildApp): Future[Unit] =
    val url = s"${AppConfigs.serverUrl}/api/aws/codebuild/app"
    fetch(url, "PUT", Some(awsApp.toNative), defaultHeaders)
      .map(_ => ())
  def delete(awsApp: AwsCodeBuildApp): Future[Unit] =
    val url = s"${AppConfigs.serverUrl}/api/aws/codebuild/app"
    val body = Dynamic.literal("id" -> awsApp.id)
    fetch(url, "DELETE", Some(body), defaultHeaders)
      .map(_ => ())
  def get(id: Int): Future[ApiResult[AwsCodeBuildApp]] =
    val url = s"${AppConfigs.serverUrl}/api/aws/codebuild/app/$id"
    fetch(url, "GET", None, defaultHeaders)
      .map(r => NativeConverter[ApiResult[AwsCodeBuildApp]].fromNative(r))
  def clone(id: Int): Future[ApiResult[AwsCodeBuildApp]] =
    val url = s"${AppConfigs.serverUrl}/api/aws/codebuild/app/clone/$id"
    fetch(url, "GET", None, defaultHeaders)
      .map(r => NativeConverter[ApiResult[AwsCodeBuildApp]].fromNative(r))
