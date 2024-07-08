package com.swarm.api

import com.sun.net.httpserver.Authenticator.Result
import com.swarm.api.ApiServer.{ApiResult, defaultHeaders, fetch}
import com.swarm.configs.AppConfigs
import com.swarm.models.{Stats, StatsItem}
import org.getshaka.nativeconverter.NativeConverter

import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.Future
import scala.scalajs.js.Dynamic

object ApiStats:

  def report(id: Int): Future[ApiResult[List[StatsItem]]] =
    val url = s"${AppConfigs.serverUrl}/api/stats/report/$id"
    fetch(url, "GET", None, defaultHeaders)
      .map(r => NativeConverter[ApiResult[List[StatsItem]]].fromNative(r))

  def list(): Future[ApiResult[List[Stats]]] =
    val url = s"${AppConfigs.serverUrl}/api/stats"
    fetch(url, "GET", None, defaultHeaders)
      .map(r => NativeConverter[ApiResult[List[Stats]]].fromNative(r))

  def save(stats: Stats): Future[ApiResult[Stats]] =
    val url = s"${AppConfigs.serverUrl}/api/stats"
    fetch(url, "POST", Some(stats.toNative), defaultHeaders)
      .map(r => NativeConverter[ApiResult[Stats]].fromNative(r))

  def update(stats: Stats): Future[ApiResult[Stats]] =
    val url = s"${AppConfigs.serverUrl}/api/stats"
    fetch(url, "PUT", Some(stats.toNative), defaultHeaders)
      .map(r => NativeConverter[ApiResult[Stats]].fromNative(r))

  def delete(stats: Stats): Future[Unit] =
    val url = s"${AppConfigs.serverUrl}/api/stats"
    val body = Dynamic.literal("id" -> stats.id)
    fetch(url, "DELETE", Some(body), defaultHeaders)
      .map(_ => ())

  def get(id: Int): Future[ApiResult[Stats]] =
    val url = s"${AppConfigs.serverUrl}/api/stats/$id"
    fetch(url, "GET", None, defaultHeaders)
      .map(r => NativeConverter[ApiResult[Stats]].fromNative(r))
