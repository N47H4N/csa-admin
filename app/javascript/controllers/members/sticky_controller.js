import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static get targets() {
    return ["container"]
  }
  static get values() {
    return {
      offset: Number,
      desktopOffset: Number
    }
  }
  static get classes() {
    return ["sticky"]
  }

  connect() {
    var offset =
      window.innerWidth <= 768 ? this.offsetValue : this.desktopOffsetValue
    this.application.offset = this.containerTarget.offsetTop + offset
  }

  update() {
    if (window.scrollY >= this.application.offset) {
      this.containerTarget.classList.add(...this.stickyClasses)
    } else {
      this.containerTarget.classList.remove(...this.stickyClasses)
    }
  }
}
