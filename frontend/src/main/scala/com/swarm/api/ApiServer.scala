package com.swarm.api

import br.com.mobilemind.nconv.custom.JsonMapper.Mappeable
import com.swarm.configs.AppConfigs
import com.swarm.models.Models.{CmdResult, Service}
import com.swarm.util.Cookie
import org.scalajs.dom

import scalajs.js
import scalajs.js.JSON
import scala.concurrent.Future
import scala.scalajs.js.undefined
import scala.concurrent.ExecutionContext.Implicits.global
import js.Thenable.Implicits.*
import org.getshaka.nativeconverter.{NativeConverter, fromJson, fromNative}

import scala.annotation.internal.MappedAlternative

object ApiServer:

  case class ApiResult[T](data: T) derives NativeConverter

  def defaultHeaders =
    val token = getToken()
    val headers = Map(
      "Content-Type" -> "application/json",
      "Accept" -> "application/json"
    )
    token.map(s => headers + ("Authorization" -> s"Bearer $s")).getOrElse(headers)

  def getToken(): Option[String] =
    Cookie.getCookie("SwarmAdminToken")

  def fetch(
    url: String,
    method: String,
    body: Option[js.Any],
    headers: Map[String, String]
  ): Future[js.Dynamic] =
    val (m, b, h) = (method, body, headers)
    val p = dom.fetch(
      url,
      new dom.RequestInit {
        this.body = b.map(s => JSON.stringify(s)).getOrElse(undefined)
        this.method = m.asInstanceOf[dom.HttpMethod]
        this.headers = convertMapToJsArray(h)

      }
    )

    // p.recover(err => ApiResult(error = true, message = Some(tryStrErrorMessage(err.getMessage))))

    val responseData = for
      response <- p
      text <- response.text()
    yield (response.status, response.statusText, text)

    val resp =
      for (code, line, body) <- responseData
      yield (code, line, body)

    resp
      .map((code, line, body) => {
        try
          JSON.parse(body)
        catch _ => js.Dynamic.literal(error = true, message = s"Status: $code, Text: $line")
      })

  private def convertMapToJsArray(headers: Map[String, String]): js.Array[js.Array[String]] =
    val arr = headers.map((k, v) => js.Array(k, v)).toArray
    js.Array(arr*)
