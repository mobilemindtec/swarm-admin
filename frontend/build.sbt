resolvers += Resolver.mavenLocal
resolvers += "Mobile Mind" at "https://raw.githubusercontent.com/mobilemindtech/m2/master"

ThisBuild / name := "Swarm Admin"
ThisBuild / scalaVersion := "3.8.2"

lazy val app = (project in file("."))
  .enablePlugins(ScalaJSPlugin, LiveReloadJSPlugin)
  .settings(
    name := "swarm-admin",
    livereloadCopyJSTo := Some(baseDirectory.value / ".." / "backend" / "public" / "assets" / "js"),
    libraryDependencies ++= Seq(
      // "com.raquo" %%% "laminar" % "18.0.0-M3",
      "ru.pavkin" %%% "scala-js-momentjs" % "0.11.0",
      "org.querki" %%% "jquery-facade" % "2.2",
      "org.getshaka" %%% "native-converter" % "0.10.1",
      "dev.frontroute" %%% "frontroute" % "0.20.0-M3",
      "io.scalaland" %%% "chimney" % "1.8.2",
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
