import { Controller } from "@hotwired/stimulus"

// Show/Hide button next to a password field
export default class extends Controller {
  static targets = ["input", "button"]
  static values = { show: String, hide: String }

  toggle() {
    const visible = this.inputTarget.type === "password"
    this.inputTarget.type = visible ? "text" : "password"
    this.buttonTarget.textContent = visible ? this.hideValue : this.showValue
    this.buttonTarget.setAttribute("aria-pressed", String(visible))
  }
}
