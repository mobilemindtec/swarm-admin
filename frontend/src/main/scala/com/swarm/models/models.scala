package com.swarm.models

import org.getshaka.nativeconverter.NativeConverter

object Models:

  case class Service(
    id: String,
    name: String,
    replicas: Option[String] = None,
    ports: Option[String] = None,
    image: Option[String] = None,
    node: Option[String] = None,
    err: Option[String] = None,
    desiredState: Option[String] = None,
    currentState: Option[String] = None
  ) derives NativeConverter
