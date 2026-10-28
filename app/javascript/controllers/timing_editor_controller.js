import { Controller } from "@hotwired/stimulus"
import YouTubeMedia from "lib/youtube_media"

// Admin timing editor: play the routine's video and stamp where each movement starts.
// "Mark next" (or the M key) writes the video time into the next row and moves on.
export default class extends Controller {
  static targets = ["video", "youtube", "start", "row", "now"]

  connect() {
    if (this.hasVideoTarget) this.media = this.videoTarget
    else if (this.hasYoutubeTarget) this.media = new YouTubeMedia(this.youtubeTarget, this.youtubeTarget.dataset.videoId)
    if (this.media) {
      this.onTime = () => { this.nowTarget.textContent = this.format(this.media.currentTime) }
      this.media.addEventListener("timeupdate", this.onTime)
    }
    this.cursor = 0
    this.highlight()
  }

  disconnect() {
    if (!this.media) return
    this.media.removeEventListener("timeupdate", this.onTime)
    this.media.destroy?.()
    this.media = null
  }

  markNext() {
    if (this.cursor < this.startTargets.length) this.stamp(this.cursor)
  }

  mark(event) {
    this.stamp(event.params.index)
  }

  jump(event) {
    const t = Number(this.startTargets[event.params.index].value) || 0
    this.media.currentTime = t
    this.media.play().catch(() => {})
    this.cursor = event.params.index + 1
    this.highlight()
  }

  // M marks the next movement, unless you are typing in a field
  key(event) {
    if (event.key !== "m" && event.key !== "M") return
    if (event.metaKey || event.ctrlKey || event.altKey || event.target.closest("input, textarea, select")) return
    event.preventDefault()
    this.markNext()
  }

  stamp(i) {
    if (!this.media) return
    this.startTargets[i].value = this.media.currentTime.toFixed(1)
    this.cursor = i + 1
    this.highlight()
  }

  highlight() {
    this.rowTargets.forEach((row, i) => row.classList.toggle("is-next", i === this.cursor))
    this.rowTargets[this.cursor]?.scrollIntoView({ block: "nearest" })
  }

  format(sec) {
    const s = Math.max(0, sec)
    return `${Math.floor(s / 60)}:${(s % 60).toFixed(1).padStart(4, "0")}`
  }
}
