import { Controller } from "@hotwired/stimulus"
import { render3d } from "lib/figure3d"

const SVG_NS = "http://www.w3.org/2000/svg"
const SHAPES = 14

// 图解: draws a movement's poses from the 3D figure. Picking a figure enlarges it, highlights its step
// and asks the routine player to jump to that point of the movement.
export default class extends Controller {
  static targets = ["view", "thumb", "angle", "angleName", "caption", "step", "stepItem", "stepText"]
  static values = { poses: Array, start: Number, duration: Number, number: Number }

  connect() {
    this.k = 0
    this.az = -35
    this.render()
  }

  pick(event) {
    this.k = Number(event.currentTarget.dataset.k)
    this.render()
    const time = this.startValue + this.durationValue * this.k / this.posesValue.length + 0.05
    this.dispatch("seek", { detail: { time } })
  }

  setAngle(event) {
    this.az = Number(event.currentTarget.dataset.az)
    this.render()
  }

  render() {
    const poses = this.posesValue
    const figures = poses.map((pose, k) => render3d(pose, this.az, poses[k + 1] || null))
    this.draw(this.viewTarget, figures[this.k])
    this.thumbTargets.forEach((el, k) => {
      this.draw(el.querySelector("svg"), figures[k])
      el.setAttribute("aria-pressed", String(k === this.k))
    })

    const angle = this.angleTargets.find((el) => Number(el.dataset.az) === this.az)
    this.angleTargets.forEach((el) => el.setAttribute("aria-pressed", String(el === angle)))
    this.angleNameTarget.textContent = angle?.textContent.trim() || ""

    const caption = `图 ${this.numberValue}-${this.k + 1}`
    this.captionTarget.textContent = caption
    this.viewTarget.setAttribute("aria-label", caption)
    this.stepTarget.textContent = this.stepTextTargets[this.k]?.textContent || ""
    this.stepItemTargets.forEach((el, k) => el.classList.toggle("is-active", k === this.k))
  }

  draw(svg, f) {
    const parts = [this.el("ellipse", { class: "fig-ground", cx: 60, cy: f.gy, rx: 30, ry: 4 })]
    for (let i = 0; i < SHAPES; i++) {
      if (f[`s${i}`]) parts.push(this.el("path", { class: "fig-body", d: f[`s${i}`] }))
    }
    if (f.btn) parts.push(this.el("path", { class: "fig-line", d: f.btn }))
    parts.push(this.el("ellipse", { class: "fig-body", cx: f.hx, cy: f.hy, rx: f.hrx, ry: f.hry }))
    parts.push(this.el("path", { class: "fig-hair", d: f.hair }))
    if (f.arc) parts.push(this.el("path", { class: "fig-arc", d: f.arc }), this.el("path", { class: "fig-tip", d: f.tip }))
    svg.replaceChildren(...parts)
  }

  el(name, attrs) {
    const node = document.createElementNS(SVG_NS, name)
    for (const [key, value] of Object.entries(attrs)) node.setAttribute(key, value)
    return node
  }
}
