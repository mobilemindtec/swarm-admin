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
  ) derives NativeConverter:

    def hasError = this.error.nonEmpty

  case class AuthenticatorStatus(enabled: Boolean) derives NativeConverter

  case class AuthenticatorPair(html: String) derives NativeConverter

  def login(username: String, password: String, code: String): Future[ApiAuthResult] =
    val url = s"${AppConfigs.serverUrl}/login"
    val payload = js.Dynamic.literal(
      username = username, 
      password = password,
      code = code
    )
    fetch(url, "POST", Some(payload), defaultHeaders)
      .map(r => NativeConverter[ApiAuthResult].fromNative(r))

  def authenticatorStatus: Future[AuthenticatorStatus] =
    val url = s"${AppConfigs.serverUrl}/api/authenticator/enabled"
    fetch(url, "GET", None, defaultHeaders)
      .map(r => NativeConverter[AuthenticatorStatus].fromNative(r))

  def authenticatorPair: Future[AuthenticatorPair] =
    val url = s"${AppConfigs.serverUrl}/api/authenticator/pair"
    fetch(url, "GET", None, defaultHeaders)
      .map(r => NativeConverter[AuthenticatorPair].fromNative(r))
