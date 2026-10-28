import { Controller } from "@hotwired/stimulus"
import YouTubeMedia from "lib/youtube_media"

// Admin timing editor: play the routine's video and stamp where each movement starts.
// "Mark next" (or the M key) writes the video time into the next row and moves on, and a pasted
// list of times (e.g. from an AI that watched the video) fills every row at once.
export default class extends Controller {
  static targets = ["video", "youtube", "start", "row", "now", "paste", "pasteResult", "playing", "name", "follow"]

  connect() {
    if (this.hasVideoTarget) this.media = this.videoTarget
    else if (this.hasYoutubeTarget) this.media = new YouTubeMedia(this.youtubeTarget, this.youtubeTarget.dataset.videoId)
    if (this.media) {
      this.onTime = () => {
        this.nowTarget.textContent = this.format(this.media.currentTime)
        this.track(this.media.currentTime)
      }
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

  // Fills rows from lines like "12 34.5", "12. 0:34.5", "END 305" or "12 34.5 ?"; "?" marks a guess
  fill() {
    const byKey = new Map(this.startTargets.map((input) => [String(input.dataset.key), input]))
    const unsure = [], found = new Set()
    let filled = 0
    for (const raw of this.pasteTarget.value.split(/\r?\n/)) {
      // Drop markdown bold/code, bullets and table pipes that chat answers often add
      const line = raw.replace(/[*_`]/g, "").replace(/\|/g, " ").replace(/^\s*[-•]\s+/, "")
      const match = line.match(/^\s*#?(\d+|end)\b\s*[.:)\-–]?\s*(\d+:\d{1,2}(?:[.,]\d+)?|\d+(?:[.,]\d+)?)(.*)$/i)
      const input = match && byKey.get(match[1].toLowerCase())
      if (!input) continue
      input.value = this.seconds(match[2]).toFixed(1)
      const guess = match[3].includes("?")
      input.closest("tr").classList.toggle("is-unsure", guess)
      if (guess) unsure.push(match[1])
      found.add(match[1].toLowerCase())
      filled++
    }

    const missing = [...byKey.keys()].filter((key) => !found.has(key))
    const result = this.pasteResultTarget.dataset
    this.pasteResultTarget.textContent = [
      result.filled.replace("%{count}", filled),
      missing.length ? result.missing.replace("%{list}", missing.join(", ")) : null,
      unsure.length ? result.unsure.replace("%{list}", unsure.join(", ")) : null
    ].filter(Boolean).join(" ")
  }

  // "34.5" or "0:34.5" (minutes:seconds) to seconds
  seconds(text) {
    const [a, b] = text.replace(",", ".").split(":")
    return b === undefined ? Number(a) : Number(a) * 60 + Number(b)
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

  // Highlights the movement playing now and, while "Follow the video" is on, keeps it in view
  track(t) {
    const starts = this.startTargets.map((input) => Number(input.value))
    let i = -1
    // The last row is the routine's end, not a movement
    for (let k = 0; k < starts.length - 1; k++) if (starts[k] <= t) i = k
    if (i === this.playingIndex) return
    this.playingIndex = i
    this.rowTargets.forEach((row, k) => row.classList.toggle("is-playing", k === i))
    if (this.hasPlayingTarget) this.playingTarget.textContent = i >= 0 ? this.nameTargets[i].textContent : ""
    if (i >= 0 && this.hasFollowTarget && this.followTarget.checked) {
      this.rowTargets[i].scrollIntoView({ block: "center", behavior: "smooth" })
    }
  }

  highlight() {
    // A row checked by hand is no longer a guess
    this.rowTargets[this.cursor - 1]?.classList.remove("is-unsure")
    this.rowTargets.forEach((row, i) => row.classList.toggle("is-next", i === this.cursor))
    if (!this.hasFollowTarget || !this.followTarget.checked) this.rowTargets[this.cursor]?.scrollIntoView({ block: "nearest" })
  }

  format(sec) {
    const s = Math.max(0, sec)
    return `${Math.floor(s / 60)}:${(s % 60).toFixed(1).padStart(4, "0")}`
  }
}
