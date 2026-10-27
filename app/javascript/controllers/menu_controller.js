import { Controller } from "@hotwired/stimulus"

// Phone header menu: the button opens and closes it; Escape or a tap outside closes it
export default class extends Controller {
  static targets = ["button", "panel"]

  toggle() {
    this.open(!this.element.classList.contains("is-open"))
  }

  close() {
    this.open(false)
  }

  closeOutside(event) {
    if (!this.element.contains(event.target)) this.close()
  }

  open(open) {
    this.element.classList.toggle("is-open", open)
    this.buttonTarget.setAttribute("aria-expanded", String(open))
  }
}
