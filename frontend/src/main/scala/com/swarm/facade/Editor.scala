package com.swarm.facade

import org.scalajs.dom.Element

import scala.scalajs.js
import scala.scalajs.js.annotation.{JSGlobal, JSImport}

class EditorOpts(val element: Element) extends js.Object

object EditorOpts:
  def apply(element: Element): EditorOpts = new EditorOpts(element)

@js.native
trait EditorCodeMirror extends js.Object:
  def getValue(): String = js.native

  def setValue(v: String): Unit = js.native

@js.native
@JSGlobal
class Editor extends js.Object:

  def apply(): Editor = js.native

  val codemirror: EditorCodeMirror = js.native

  def render(element: Element): Unit = js.native

  def render(): Unit = js.native
  def markdown(s: String): String = js.native

/*
function loadMdEditor() {
			console.log("loadMdEditor")
			if($(".md-content")){
                // textarea.md-content
				window.editor = new Editor({ element: $(".md-content")[0] });
				editor.render();
			}
	}

	function preSave(){
			console.log("preSave")
			var value = editor.codemirror.getValue()
			$(".md-content").val(value)
			$(".md-html").val(Editor.markdown(value))
	}

	function preSaveEvent() {
			console.log("preSaveEvent")
			$(".btn-save").on('click', preSave)

	}
 * */
