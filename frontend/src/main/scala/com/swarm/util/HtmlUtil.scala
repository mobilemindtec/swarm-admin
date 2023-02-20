package com.swarm.util

import org.scalajs.dom
import org.scalajs.dom.HTMLInputElement

object HtmlUtil:

  def getValueById(id: String) =
    dom.document.getElementById(id).asInstanceOf[HTMLInputElement].value
