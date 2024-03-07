package com.swarm.api

import com.sun.net.httpserver.Authenticator.Result
import com.swarm.api.ApiServer.{ApiResult, defaultHeaders, fetch}
import com.swarm.configs.AppConfigs
import com.swarm.models.Stack
import org.getshaka.nativeconverter.NativeConverter

import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.Future
import scala.scalajs.js.Dynamic

object ApiStack:

  def list(): Future[ApiResult[List[Stack]]] =
    val url = s"${AppConfigs.serverUrl}/api/stack"
    fetch(url, "GET", None, defaultHeaders)
      .map(r => NativeConverter[ApiResult[List[Stack]]].fromNative(r))

  def save(stack: Stack): Future[ApiResult[Stack]] =
    val url = s"${AppConfigs.serverUrl}/api/stack"
    fetch(url, "POST", Some(stack.toNative), defaultHeaders)
      .map(r => NativeConverter[ApiResult[Stack]].fromNative(r))

  def update(stack: Stack): Future[ApiResult[Stack]] =
    val url = s"${AppConfigs.serverUrl}/api/stack"
    fetch(url, "PUT", Some(stack.toNative), defaultHeaders)
      .map(r => NativeConverter[ApiResult[Stack]].fromNative(r))

  def delete(stack: Stack): Future[Unit] =
    val url = s"${AppConfigs.serverUrl}/api/stack"
    val body = Dynamic.literal("id" -> stack.id)
    fetch(url, "DELETE", Some(body), defaultHeaders)
      .map(_ => ())

  def get(id: Int): Future[ApiResult[Stack]] =
    val url = s"${AppConfigs.serverUrl}/api/stack/$id"
    fetch(url, "GET", None, defaultHeaders)
      .map(r => NativeConverter[ApiResult[Stack]].fromNative(r))
