package com.swarm.api

import org.scalajs.dom

import scala.concurrent.Future
import scala.scalajs.js.undefined
import scala.concurrent.ExecutionContext.Implicits.global
import scalajs.js
import js.Thenable.Implicits.*
import scalajs.js.{JSON}

object ApiServer:

  private def fetch[T](
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
