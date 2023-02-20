package com.swarm.util

import moment.Moment
import org.scalajs.dom

import scala.scalajs.js

object DateUtil:

  val pattern = "DD/MM/YYYY"
  val fromPattern = "YYYY-MM-DDTHH:mm:ss.SSSZ"

  def fromStr(str: String): Option[js.Date] =
    println(s"parse date ${str}")
    val m = Moment(str, pattern)
    m.isValid() match
      case true => Some(m.toDate())
      case _    => None

  def toStr(dt: js.Date): String = toStr(Some(dt))

  def toStr(dt: Option[js.Date]): String =
    dom.window.console.log(Moment(dt.get))
    if dt.nonEmpty then Moment(dt.get).utcOffset(0).format(pattern) else ""

  def isValid(str: String) = Moment(str, pattern).isValid()
