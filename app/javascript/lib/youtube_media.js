// Wraps a YouTube embed in the small part of the <video> element API the routine player uses:
// play(), pause(), currentTime, playbackRate, paused and the timeupdate / play / pause events.
// YouTube has no timeupdate event, so the time is polled while the video plays.

const POLL_MS = 200
let api

function loadApi() {
  if (window.YT?.Player) return Promise.resolve(window.YT)
  api ||= new Promise((resolve) => {
    const previous = window.onYouTubeIframeAPIReady
    window.onYouTubeIframeAPIReady = () => { previous?.(); resolve(window.YT) }
    const script = document.createElement("script")
    script.src = "https://www.youtube.com/iframe_api"
    document.head.append(script)
  })
  return api
}

export default class YouTubeMedia extends EventTarget {
  constructor(container, videoId) {
    super()
    this.videoId = videoId
    this.paused = true
    this.started = false
    this.time = 0
    this.rate = 1

    // YouTube replaces the element it is given, so give it a fresh child and keep the container
    const mount = document.createElement("div")
    container.replaceChildren(mount)
    this.ready = loadApi().then((YT) => new Promise((resolve) => {
      this.player = new YT.Player(mount, {
        videoId,
        host: "https://www.youtube-nocookie.com",
        playerVars: { playsinline: 1, rel: 0, modestbranding: 1 },
        events: {
          onReady: () => {
            if (this.time > 0) this.cue(this.time)
            this.player.setPlaybackRate(this.rate)
            resolve()
          },
          onStateChange: (event) => this.stateChanged(event.data)
        }
      })
    }))
  }

  get currentTime() {
    return this.started && this.player?.getCurrentTime ? this.player.getCurrentTime() : this.time
  }

  set currentTime(t) {
    this.time = t
    if (!this.player?.seekTo) return
    // Seeking a video that has not started would start it, so cue it at that time instead
    if (this.started) this.player.seekTo(t, true)
    else this.cue(t)
  }

  set playbackRate(rate) {
    this.rate = rate
    this.player?.setPlaybackRate?.(rate)
  }

  play() {
    return this.ready.then(() => this.player.playVideo())
  }

  pause() {
    this.player?.pauseVideo?.()
  }

  destroy() {
    this.stopPolling()
    this.player?.destroy?.()
  }

  // ---- Internals ----

  cue(t) {
    this.player.cueVideoById({ videoId: this.videoId, startSeconds: t })
  }

  stateChanged(state) {
    const { PLAYING, PAUSED, ENDED } = window.YT.PlayerState
    if (state === PLAYING) {
      this.started = true
      this.paused = false
      this.startPolling()
      this.dispatchEvent(new Event("play"))
    } else if (state === PAUSED || state === ENDED) {
      this.paused = true
      this.stopPolling()
      this.dispatchEvent(new Event("timeupdate"))
      this.dispatchEvent(new Event("pause"))
    }
  }

  startPolling() {
    this.stopPolling()
    this.poll = setInterval(() => this.dispatchEvent(new Event("timeupdate")), POLL_MS)
  }

  stopPolling() {
    clearInterval(this.poll)
    this.poll = null
  }
}
