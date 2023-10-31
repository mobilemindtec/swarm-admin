package com.swarm.models

import org.getshaka.nativeconverter.NativeConverter
import br.com.mobilemind.nconv.custom.JsonMapper.{JsField, JsFieldType, JsFields, Mappeable, MapperConfig, MapperOf, getFields}

import scala.scalajs.js

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
  ) derives NativeConverter:
    def serviceName = if name.contains(".") then name.split("\\.")(0) else name

  case class CmdResult(error: Option[Boolean] = None, messages: Option[List[String]] = None)
    derives NativeConverter

  case class Stack(
    @JsField id: Int,
    @JsField name: String,
    @JsField content: String,
    @JsField enabled: Boolean,
    @JsField(name = "updated_at") updatedAt: String
  ) extends Mappeable[Stack]
    derives NativeConverter:
    override def toJS: js.Any = this.toNative

    override def fromJS(s: js.Dynamic): Stack = NativeConverter[Stack].fromNative(s)

  case class AwsCodeBuildApp(
    id: Int,
    stackVarName: String,
    versionTag: String,
    awsEcrRepositoryName: String,
    awsAccountId: String,
    awsRegion: String,
    awsUrl: String,
    codeBase: String,
    buildVars: String,
    stackId: Int,
    updatedAt: String
  ) derives NativeConverter

  object ConverterMappers:
    given stackFields: JsFields[Stack] = getFields[Stack]

    given mapperConfig: MapperConfig = MapperConfig(
      MapperConfig.newMapperOf[Stack]
    )
