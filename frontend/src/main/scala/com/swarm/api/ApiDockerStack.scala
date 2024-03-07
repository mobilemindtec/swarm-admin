package com.swarm.api

import com.swarm.api.ApiServer.{ApiResult, defaultHeaders, fetch}
import com.swarm.configs.AppConfigs
import com.swarm.models.CmdResult
import org.getshaka.nativeconverter.NativeConverter
import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.Future

object ApiDockerStack:
  def rm(stackName: String): Future[ApiResult[CmdResult]] =
    val url = s"${AppConfigs.serverUrl}/api/docker/stack/rm/$stackName"
    fetch(url, "GET", None, defaultHeaders)
      .map(r => NativeConverter[ApiResult[CmdResult]].fromNative(r))

  def deploy(stackName: String): Future[ApiResult[CmdResult]] =
    val url = s"${AppConfigs.serverUrl}/api/docker/stack/deploy/$stackName"
    fetch(url, "GET", None, defaultHeaders)
      .map(r => NativeConverter[ApiResult[CmdResult]].fromNative(r))
