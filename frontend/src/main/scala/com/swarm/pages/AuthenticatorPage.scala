package com.swarm.pages

import com.raquo.laminar.api.L.*
import com.swarm.api.ApiAuth

import scala.concurrent.ExecutionContext.Implicits.global
import scala.util.{Failure, Success}

object AuthenticatorPage:

  val html = Var[Option[String]](None)

  def apply() = node()

  private def load =
    ApiAuth.authenticatorPair.onComplete {
      case Success(info) =>
        val link = info.html.split("src").last.split('\'')(1)
        html.update(_ => Some(link))
      case Failure(err) => html.update(_ => Some(err.getMessage))
    }

  private def node() =
    div(
      cls("text-center"),
      onMountCallback(_ => load),
      paddingTop("50px"),
      h2("Authenticator"),
      p(
        "Read the QR code using your authenticator app such as Google or Microsoft Authenticator"
      ),
      child.maybe <-- html.signal.map(_.map(s => img(src(s))))
    )
