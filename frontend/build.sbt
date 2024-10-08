ThisBuild / name := "Swarm Admin"
ThisBuild / scalaVersion := "3.5.0"

lazy val app = (project in file("."))
  .enablePlugins(ScalaJSPlugin, LiveReloadJSPlugin)
  .settings(
    name := "swarm-admin",
    livereloadCopyJSTo := Some(baseDirectory.value / ".." / "backend" / "public" / "assets" / "js"),
    libraryDependencies ++= Seq(
      "com.raquo" %%% "laminar" % "17.1.0",
      ("ru.pavkin" %%% "scala-js-momentjs" % "0.10.9") cross CrossVersion.for3Use2_13,
      ("org.querki" %%% "jquery-facade" % "2.1") cross CrossVersion.for3Use2_13 excludeAll (
        ExclusionRule(organization = "org.scala-js")
      ),
      "org.getshaka" %%% "native-converter" % "0.10.0-SNAPSHOT",
      "io.frontroute" %%% "frontroute" % "0.19.0",
      "io.scalaland" %%% "chimney" % "1.4.0",
      ("org.scala-js" %%% "scalajs-java-securerandom" % "1.0.0") cross CrossVersion.for3Use2_13
    ),
    scalaJSUseMainModuleInitializer := true,
    (artifactPath / compile / fastOptJS) := Attributed
      .blank(livereloadCopyJSTo.value.get / "main.js"),
    (artifactPath / compile / fullOptJS) := Attributed.blank(
      livereloadCopyJSTo.value.get / "main.js"
    )
  )

Compile / run / fork := true
ThisBuild / usePipelining := true
