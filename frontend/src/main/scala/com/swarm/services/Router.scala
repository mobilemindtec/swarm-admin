package com.swarm.services

import org.scalajs.dom.window.document

object Router:

  def navigate(path: String) =
    if document.location.pathname != path then document.location.href = path

  def home() = navigate("/")

  def login() = navigate("/app/login")
