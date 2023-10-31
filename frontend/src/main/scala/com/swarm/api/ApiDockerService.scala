package com.swarm.api

import com.swarm.configs.AppConfigs
import org.getshaka.nativeconverter.NativeConverter

import scala.concurrent.Future
import com.swarm.api.ApiServer.*
import com.swarm.models.Models.{CmdResult, Service}

import scala.concurrent.ExecutionContext.Implicits.global

object ApiDockerService:

  def rm(serviceName: String): Future[ApiResult[CmdResult]] =
    val url = s"${AppConfigs.serverUrl}/api/docker/service/rm/$serviceName"
    fetch(url, "GET", None, defaultHeaders)
      .map(r => NativeConverter[ApiResult[CmdResult]].fromNative(r))

  def update(serviceName: String): Future[ApiResult[CmdResult]] =
    val url = s"${AppConfigs.serverUrl}/api/docker/service/update/$serviceName"
    fetch(url, "GET", None, defaultHeaders)
      .map(r => NativeConverter[ApiResult[CmdResult]].fromNative(r))

  def logs(serviceName: String): Future[ApiResult[CmdResult]] =
    val url = s"${AppConfigs.serverUrl}/api/docker/service/logs/get/$serviceName"
    fetch(url, "GET", None, defaultHeaders)
      .map(r => NativeConverter[ApiResult[CmdResult]].fromNative(r))

  def ls(): Future[ApiResult[List[Service]]] =
    val url = s"${AppConfigs.serverUrl}/api/docker/service/ls"
    fetch(url, "GET", None, defaultHeaders)
      .map(r => NativeConverter[ApiResult[List[Service]]].fromNative(r))

  def ps(id: String): Future[ApiResult[List[Service]]] =
    val url = s"${AppConfigs.serverUrl}/api/docker/service/ps/$id"
    fetch(url, "GET", None, defaultHeaders)
      .map(r => NativeConverter[ApiResult[List[Service]]].fromNative(r))
