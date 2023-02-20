package com.swarm.pages.comps

import com.raquo.laminar.api.L.*

object Theme:

  def terminal(children: Mod[HtmlElement]*) =
    div(cls("terminal"), children)
