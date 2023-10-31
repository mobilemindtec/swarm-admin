package com.swarm.api

import com.swarm.configs.AppConfigs
import org.getshaka.nativeconverter.NativeConverter

import scala.concurrent.Future
import scala.scalajs.js
import com.swarm.api.ApiServer._
import scala.concurrent.ExecutionContext.Implicits.global

object ApiAuth:
  case class ApiAuthResult(
                            token: Option[String] = None,
                            expires_at: Option[Long] = None,
                            error: Option[String] = None
                          )derives NativeConverter:

    def hasError = this.error.nonEmpty

  def login(username: String, password: String): Future[ApiAuthResult] =
    val url = s"${AppConfigs.serverUrl}/login"
    val payload = js.Dynamic.literal(username = username, password = password)
    fetch(url, "POST", Some(payload), defaultHeaders)
      .map(r => NativeConverter[ApiAuthResult].fromNative(r))
