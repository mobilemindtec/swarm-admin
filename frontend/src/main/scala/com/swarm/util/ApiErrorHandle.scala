package com.swarm.util

import com.raquo.laminar.api.L.Var
import com.swarm.api.ApiServer.ApiResult

import scala.util.{Failure, Success, Try}

object ApiErrorHandle:

  type PF[T] = PartialFunction[Try[ApiResult[T]], Unit]

  type PFUnit[T] = PartialFunction[Try[T], Unit]

  def handle[T](message: Var[Option[String]])(fn: PF[T]): PF[T] =
    fn orElse {
      case Success(ApiResult(_, Some(true), msg, messages)) =>
        message.update(_ => msg.orElse(messages.map(_.mkString(", "))))
      case Success(_) =>
        message.update(_ => Some("unknown error"))
      case Failure(err) => message.update(_ => Some(s"${err.getMessage}"))
    }

  def handleUnit[T](message: Var[Option[String]])(fn: PFUnit[T]): PFUnit[T] =
    fn orElse { case Failure(err) =>
      message.update(_ => Some(s"${err.getMessage}"))
    }
