import { Controller } from "@hotwired/stimulus"
import YouTubeMedia from "lib/youtube_media"

// Keeps the video, the movement timeline, the carpet path and the movement list in sync.
// Selecting a movement seeks to its start; playing moves the active movement along.
// The video is an upload or a YouTube embed; without either it runs a practice clock, so the routine can still be followed.
export default class extends Controller {
  static targets = [
    "video", "youtube", "clock", "playButton", "playIcon", "pauseIcon", "playhead", "segment", "loopButton", "speed",
    "nowCn", "nowNum", "nowZh", "nowPy", "nowTr", "legendNow",
    "donePath", "activePath", "label", "halo", "dot",
    "list", "row", "detail"
  ]
  static values = { moves: Array, total: Number, selected: Number, start: Array, playLabel: String, pauseLabel: String }

  connect() {
    this.time = 0
    this.rate = 1
    this.loop = false
    this.playing = false
    this.active = -1
    // Routines whose carpet path is not measured yet have no start point and no end points
    this.points = [this.startValue.length ? this.startValue : null, ...this.movesValue.map((m) => m.x == null ? null : [m.x * 100, m.y * 100])]

    // Both media expose the same small API: play(), pause(), currentTime, playbackRate and events
    if (this.hasVideoTarget) this.media = this.videoTarget
    else if (this.hasYoutubeTarget) this.media = new YouTubeMedia(this.youtubeTarget, this.youtubeTarget.dataset.videoId)
    if (this.media) {
      this.onTime = () => this.tick(this.media.currentTime)
      this.onPlayState = () => this.showPlaying(!this.media.paused)
      this.media.addEventListener("timeupdate", this.onTime)
      this.media.addEventListener("play", this.onPlayState)
      this.media.addEventListener("pause", this.onPlayState)
    }

    // The URL wins over the server value: ?m= changes as you browse, and Turbo restores old snapshots on Back
    const fromUrl = Number(new URL(window.location.href).searchParams.get("m"))
    const selected = this.indexOf(fromUrl || this.selectedValue)
    if (selected >= 0) {
      this.seek(this.movesValue[selected].start)
      this.showDetail(selected)
    } else {
      this.listTarget.hidden = false
      this.detailTargets.forEach((el) => { el.hidden = true })
      this.tick(0)
    }
  }

  disconnect() {
    this.stopClock()
    if (this.media) {
      this.media.removeEventListener("timeupdate", this.onTime)
      this.media.removeEventListener("play", this.onPlayState)
      this.media.removeEventListener("pause", this.onPlayState)
      this.media.destroy?.()
      this.media = null
    }
  }

  // ---- Actions ----

  toggle() {
    this.playing ? this.pause() : this.play()
  }

  // Timeline segment: seek there, keep the current panel (list or detail)
  select(event) {
    const i = this.indexOf(Number(event.currentTarget.dataset.n))
    this.seek(this.movesValue[i].start)
    if (!this.listTarget.hidden) return
    this.showDetail(i)
  }

  // Movement list row: seek and open its details
  open(event) {
    const i = this.indexOf(Number(event.currentTarget.dataset.n))
    this.seek(this.movesValue[i].start)
    this.showDetail(i)
  }

  close() {
    this.detailTargets.forEach((el) => { el.hidden = true })
    this.listTarget.hidden = false
    this.rowTargets[this.active]?.scrollIntoView({ block: "nearest" })
    this.updateUrl(null)
  }

  prev() { this.step(-1) }
  next() { this.step(1) }

  prevKey(event) { if (this.isPlainKey(event)) this.step(-1) }
  nextKey(event) { if (this.isPlainKey(event)) this.step(1) }

  playThis() {
    this.seek(this.movesValue[this.active].start)
    this.play()
  }

  toggleLoop() {
    this.loop = !this.loop
    this.loopButtonTargets.forEach((el) => el.setAttribute("aria-pressed", String(this.loop)))
  }

  setSpeed(event) {
    this.rate = Number(event.currentTarget.dataset.rate)
    if (this.media) this.media.playbackRate = this.rate
    this.speedTargets.forEach((el) => el.setAttribute("aria-pressed", String(el === event.currentTarget)))
  }

  // From a 图解 figure: jump to that point of the movement
  seekTo(event) {
    this.seek(event.detail.time)
  }

  // ---- Playback ----

  play() {
    if (this.time >= this.totalValue) this.seek(0)
    if (this.media) {
      this.media.play().catch(() => this.showPlaying(false))
    } else {
      this.last = performance.now()
      this.frame = requestAnimationFrame(this.advance)
      this.showPlaying(true)
    }
  }

  pause() {
    if (this.media) {
      this.media.pause()
    } else {
      this.stopClock()
      this.showPlaying(false)
    }
  }

  advance = (now) => {
    const t = this.time + (now - this.last) / 1000 * this.rate
    this.last = now
    if (t >= this.totalValue) {
      this.tick(this.totalValue)
      this.pause()
      return
    }
    this.tick(t)
    this.frame = requestAnimationFrame(this.advance)
  }

  stopClock() {
    if (this.frame) cancelAnimationFrame(this.frame)
    this.frame = null
  }

  seek(t) {
    if (this.media) this.media.currentTime = t
    this.tick(t)
  }

  tick(t) {
    const loopMove = this.loop && this.movesValue[this.active]
    if (loopMove && t >= loopMove.end) {
      this.seek(loopMove.start)
      return
    }
    this.time = t
    this.clockTarget.textContent = this.format(t)
    this.playheadTarget.style.left = `${Math.min(100, t / this.totalValue * 100)}%`

    const i = this.indexAt(t)
    if (i !== this.active) this.activate(i)
    this.drawActivePath(t)
  }

  showPlaying(playing) {
    this.playing = playing
    // SVG elements have no .hidden property, so set the attribute
    this.playIconTarget.toggleAttribute("hidden", playing)
    this.pauseIconTarget.toggleAttribute("hidden", !playing)
    this.playButtonTarget.setAttribute("aria-label", playing ? this.pauseLabelValue : this.playLabelValue)
  }

  // ---- Rendering ----

  activate(i) {
    const detailOpen = this.listTarget.hidden
    this.active = i
    const m = this.movesValue[i]

    this.nowCnTarget.textContent = m.cn
    this.nowNumTarget.textContent = m.n
    this.nowZhTarget.textContent = m.zh
    this.nowPyTarget.textContent = m.py
    this.nowTrTarget.textContent = m.tr
    this.legendNowTarget.textContent = `${m.n} ${m.zh}`

    this.segmentTargets.forEach((el, k) => {
      el.classList.toggle("is-done", k < i)
      el.classList.toggle("is-active", k === i)
    })
    this.rowTargets.forEach((el, k) => {
      el.classList.toggle("is-active", k === i)
      if (k === i) el.setAttribute("aria-current", "step")
      else el.removeAttribute("aria-current")
    })
    this.labelTargets.forEach((el) => {
      const n = Number(el.dataset.n)
      el.classList.toggle("is-done", n < m.n)
      el.classList.toggle("is-active", n === m.n)
    })
    this.donePathTarget.setAttribute("d", this.path(this.points.slice(0, i + 1)))

    if (detailOpen) this.showDetail(i)
  }

  // The current segment grows from the previous end point towards this movement's end point
  drawActivePath(t) {
    const m = this.movesValue[this.active]
    const from = this.points[this.active], to = this.points[this.active + 1]
    if (!from || !to) return
    const u = Math.max(0, Math.min(1, (t - m.start) / ((m.end - m.start) || 1)))
    const x = from[0] + (to[0] - from[0]) * u, y = from[1] + (to[1] - from[1]) * u
    this.activePathTarget.setAttribute("d", this.path([from, [x, y]]))
    for (const el of [this.haloTarget, this.dotTarget]) {
      el.setAttribute("cx", x.toFixed(1))
      el.setAttribute("cy", y.toFixed(1))
    }
  }

  showDetail(i) {
    this.listTarget.hidden = true
    this.detailTargets.forEach((el, k) => { el.hidden = k !== i })
    this.updateUrl(this.movesValue[i].n)
  }

  step(delta) {
    const i = Math.max(0, Math.min(this.movesValue.length - 1, this.active + delta))
    this.seek(this.movesValue[i].start)
    if (this.listTarget.hidden) this.showDetail(i)
  }

  // ---- Helpers ----

  indexOf(n) {
    return this.movesValue.findIndex((m) => m.n === n)
  }

  indexAt(t) {
    let i = 0
    this.movesValue.forEach((m, k) => { if (m.start <= t) i = k })
    return i
  }

  path(points) {
    return points.filter(Boolean).map((p, i) => `${i ? "L" : "M"}${p[0]} ${p[1]}`).join(" ")
  }

  format(sec) {
    sec = Math.floor(sec)
    return `${Math.floor(sec / 60)}:${String(sec % 60).padStart(2, "0")}`
  }


  updateUrl(n) {
    const url = new URL(window.location.href)
    if (n) url.searchParams.set("m", n)
    else url.searchParams.delete("m")
    history.replaceState(history.state, "", url)
  }

  isPlainKey(event) {
    const tag = event.target.tagName
    return !event.altKey && !event.ctrlKey && !event.metaKey && !["INPUT", "TEXTAREA", "SELECT"].includes(tag)
  }
}
