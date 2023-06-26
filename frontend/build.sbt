ThisBuild / name := "Swarm Admin"
ThisBuild / scalaVersion := "3.3.0"

lazy val app = (project in file("."))
  .enablePlugins(ScalaJSPlugin, LiveReloadJSPlugin)
  .settings(
    name := "swarm-admin",
    livereloadCopyJSTo := Some(baseDirectory.value / ".." / "backend" / "public" / "assets" / "js"),
    libraryDependencies ++= Seq(
      "com.raquo" %%% "laminar" % "15.0.1",
      ("ru.pavkin" %%% "scala-js-momentjs" % "0.10.9") cross CrossVersion.for3Use2_13,
      ("org.querki" %%% "jquery-facade" % "2.1") cross CrossVersion.for3Use2_13 excludeAll (
        ExclusionRule(organization = "org.scala-js")
      ),
      "org.getshaka" %%% "native-converter" % "0.8.0",
      "io.frontroute" %%% "frontroute" % "0.17.1",
      ("org.scala-js" %%% "scalajs-java-securerandom" % "1.0.0") cross CrossVersion.for3Use2_13
    ),
    scalaJSUseMainModuleInitializer := true,
  
    (artifactPath / compile / fastOptJS) := Attributed.blank(livereloadCopyJSTo.value.get / "main.js"),
    (artifactPath / compile / fullOptJS) := Attributed.blank(livereloadCopyJSTo.value.get / "main.js")

  )
