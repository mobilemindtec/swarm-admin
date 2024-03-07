package com.swarm.models

import org.getshaka.nativeconverter.{Json, NativeConverter}

import scala.scalajs.js

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
) derives NativeConverter:
  def serviceName = if name.contains(".") then name.split("\\.")(0) else name

case class CmdResult(error: Option[Boolean] = None, messages: Option[List[String]] = None)
  derives NativeConverter

case class Stack(
  @Json id: Int,
  @Json name: String,
  @Json content: String,
  @Json enabled: Boolean,
  @Json(name = "updated_at") updatedAt: String
) derives NativeConverter

case class AwsCodeBuildApp(
  id: Int,
  stackVarName: String,
  versionTag: String,
  awsEcrRepositoryName: String,
  awsAccountId: String,
  awsRegion: String,
  awsUrl: String,
  awsProjectName: String,
  codeBase: String,
  buildVars: String,
  lastBuildAt: String,
  stackId: Int,
  updatedAt: String,
  building: Boolean
) derives NativeConverter

case class AwsBuild(
  id: Int,
  buildId: String,
  awsCodebuildAppId: Int,
  logsGroupName: String,
  logsStreamName: String,
  logsDeepLink: String,
  startTime: String,
  endTime: String,
  currentPhase: String,
  buildStatus: String,
  appVersionTag: String,
  createdAt: String,
  updatedAt: String
) derives NativeConverter:

  def completed: Boolean = currentPhase == "COMPLETED"

  def building: Boolean = !completed
