package com.swarm.configs

object AppConfigs {
  val prod = false
  def serverUrl = if prod then "" else "http://localhost:5151"
}
