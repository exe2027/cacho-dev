// Puente con el reproductor embebido de YouTube (IFrame Player API).
// Toda la complejidad de la API de YouTube vive aquí; el lado Dart
// solo ve funciones planas y consulta el estado una vez por segundo.
// El reproductor queda en un rincón de 6x6 px casi invisible: solo
// importa su audio. La sincronía la maneja Dart comparando
// getCurrentTime() contra el instante de inicio que dicta el servidor.
window.CachoYt = (function () {
  var player = null;
  var ready = false;
  var endedFlag = false;
  var apiLoading = false;

  function ensureDiv() {
    var div = document.getElementById('cacho-yt');
    if (!div) {
      div = document.createElement('div');
      div.id = 'cacho-yt';
      div.style.cssText =
        'position:fixed;left:0;bottom:0;width:6px;height:6px;' +
        'opacity:0.05;pointer-events:none;z-index:0;overflow:hidden;';
      document.body.appendChild(div);
      var inner = document.createElement('div');
      inner.id = 'cacho-yt-player';
      div.appendChild(inner);
    }
  }

  function createPlayer() {
    if (player || !window.YT || !YT.Player) return;
    ensureDiv();
    player = new YT.Player('cacho-yt-player', {
      width: '6',
      height: '6',
      playerVars: {
        autoplay: 0,
        controls: 0,
        playsinline: 1,
        rel: 0,
        modestbranding: 1,
        disablekb: 1,
      },
      events: {
        onReady: function () { ready = true; },
        onStateChange: function (e) {
          if (e.data === 0) endedFlag = true; // YT.PlayerState.ENDED
        },
      },
    });
  }

  return {
    init: function () {
      ensureDiv();
      if (window.YT && YT.Player) { createPlayer(); return; }
      if (apiLoading) return;
      apiLoading = true;
      var prev = window.onYouTubeIframeAPIReady;
      window.onYouTubeIframeAPIReady = function () {
        if (prev) prev();
        createPlayer();
      };
      var tag = document.createElement('script');
      tag.src = 'https://www.youtube.com/iframe_api';
      document.head.appendChild(tag);
    },
    isReady: function () { return ready && !!player; },
    load: function (videoId, startSec) {
      if (!ready || !player) return;
      endedFlag = false;
      player.loadVideoById({ videoId: videoId, startSeconds: startSec || 0 });
    },
    play: function () { if (ready && player) player.playVideo(); },
    pause: function () { if (ready && player) player.pauseVideo(); },
    stop: function () { if (ready && player) { try { player.pauseVideo(); player.stopVideo(); } catch(e){} } },
    seekTo: function (sec) {
      if (ready && player) player.seekTo(sec, true);
    },
    setVolume: function (v) {
      if (ready && player) player.setVolume(Math.max(0, Math.min(100, v)));
    },
    getVolume: function () {
      return ready && player ? player.getVolume() : -1;
    },
    getCurrentTime: function () {
      return ready && player ? player.getCurrentTime() : -1;
    },
    // -1 sin empezar, 0 terminado, 1 sonando, 2 pausado, 3 cargando, 5 en cola
    getState: function () {
      return ready && player ? player.getPlayerState() : -99;
    },
    consumeEnded: function () {
      var e = endedFlag;
      endedFlag = false;
      return e;
    },
  };
})();
