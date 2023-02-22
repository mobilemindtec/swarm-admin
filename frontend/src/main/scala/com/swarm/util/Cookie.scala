package com.swarm.util

import org.scalajs.dom.document

import scala.scalajs.js.Date

object Cookie:

  def clear(key: String): Unit =
    document.cookie = s"$key=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/";

  def clearAll(): Unit =
    val Cookie = "([^=]+)=.+".r
    document.cookie.split("; ").foreach {
      case Cookie(key) => clear(key)
      case other       => println(s"Couldn't parse '$other' as a key=value cookie pair")
    }

  def setCookie(key: String, value: String, expires: Long, path: String = "/") =
    val date = new Date()
    if expires > date.getTime() then date.setTime(expires)
    else date.setTime(date.getTime() + expires)
    val expiresAt = date.toUTCString()
    document.cookie = s"$key=$value; expires=$expiresAt; path=$path"

  def getCookie(name: String): Option[String] =
    val Cookie = "([^=]+)=.+".r
    document.cookie
      .split("; ")
      .find {
        case Cookie(key) => key == name
        case _           => false
      }
      .map(_.split("=").last)
