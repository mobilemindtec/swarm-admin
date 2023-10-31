ThisBuild / name := "Swarm Admin"
ThisBuild / scalaVersion := "3.3.1"

lazy val app = (project in file("."))
  .enablePlugins(ScalaJSPlugin, LiveReloadJSPlugin)
  .settings(
    name := "swarm-admin",
    livereloadCopyJSTo := Some(baseDirectory.value / ".." / "backend" / "public" / "assets" / "js"),
    libraryDependencies ++= Seq(
      "com.raquo" %%% "laminar" % "16.0.0",
      ("ru.pavkin" %%% "scala-js-momentjs" % "0.10.9") cross CrossVersion.for3Use2_13,
      ("org.querki" %%% "jquery-facade" % "2.1") cross CrossVersion.for3Use2_13 excludeAll (
        ExclusionRule(organization = "org.scala-js")
      ),
      "org.getshaka" %%% "native-converter" % "0.9.0",
      "br.com.mobilemind.nconv.custom" %%% "native-converter-custom" % "0.0.2-SNAPSHOT",
      "io.frontroute" %%% "frontroute" % "0.18.1",
      "com.lihaoyi" %%% "upickle" % "3.1.2",
      "io.scalaland" %%% "chimney" % "0.8.0-RC1",
      ("org.scala-js" %%% "scalajs-java-securerandom" % "1.0.0") cross CrossVersion.for3Use2_13
    ),
    scalaJSUseMainModuleInitializer := true,
    (artifactPath / compile / fastOptJS) := Attributed
      .blank(livereloadCopyJSTo.value.get / "main.js"),
    (artifactPath / compile / fullOptJS) := Attributed.blank(
      livereloadCopyJSTo.value.get / "main.js"
    )
  )
