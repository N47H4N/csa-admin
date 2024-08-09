import { Controller } from "@hotwired/stimulus"
import { hide } from "components/utils"
import { debounce } from 'throttle-debounce'
import * as ace from "ace-builds"
import "ace-builds/src-noconflict/mode-liquid"
import "ace-builds/src-noconflict/mode-yaml"
import "ace-builds/src-noconflict/theme-textmate"

export default class extends Controller {
  static get targets() {
    return ["editor", "form"]
  }
  static get values() {
    return { previewPath: String }
  }

  initialize() {
    this.updatePreview = debounce(500, this.updatePreview)
  }

  editorTargetConnected(element) {
    hide(element)
    const editDiv = document.createElement("div")
    element.parentNode.insertBefore(editDiv, element)
    var editor = ace.edit(editDiv, {
      mode: 'ace/mode/' + element.dataset.mode,
      theme: 'ace/theme/textmate',
      placeholder: element.placeholder,
      highlightActiveLine: false,
      showGutter: false,
      printMargin: false,
      useSoftTabs: true,
      tabSize: 2,
      wrapBehavioursEnabled: true,
      wrap: true,
      minLines: 10,
      maxLines: 30,
      fontSize: 14
    })
    editor.renderer.setPadding(12)
    editor.getSession().setUseWorker(false)
    editor.getSession().setValue(element.value)
    editor.getSession().on('change', () => {
      element.innerHTML = editor.getSession().getValue()
      this.updatePreview()
    })
  }

  updatePreview() {
    const path = this.previewPathValue

    if (this.hasFormTarget && path) {
      const formData = new FormData(this.formTarget)
      formData.delete('_method') // remove PATCH Rails form _method
      const params = new URLSearchParams(formData)
      fetch(path, {
        method: 'POST',
        body: params
      }).then(response => response.text()).then((js) => {
        try {
          eval(js)
        } catch (e) {
          console.error(e)
        }
      })
    }
  }
}
