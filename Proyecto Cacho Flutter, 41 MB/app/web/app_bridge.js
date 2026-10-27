// Puente propio de la app (R44/R48, rediseño completo): altura
// visible real (visualViewport + safe-area-inset) y pantalla
// completa. NO toca el reproductor (web/yt_bridge.js queda intacto).
// Se carga en index.html antes de flutter_bootstrap.js.
window.CachoViewport = (function () {
  var probe = document.createElement('div');
  probe.style.cssText = 'position:fixed;top:0;left:0;width:0;height:0;' +
    'padding-top:env(safe-area-inset-top);' +
    'padding-bottom:env(safe-area-inset-bottom);' +
    'visibility:hidden;pointer-events:none;';
  document.documentElement.appendChild(probe);
  function px(v) {
    var n = parseFloat(v);
    return isNaN(n) ? 0 : n;
  }
  function safeTop() {
    return px(getComputedStyle(probe).paddingTop);
  }
  function safeBottom() {
    return px(getComputedStyle(probe).paddingBottom);
  }
  function height() {
    return (window.visualViewport && window.visualViewport.height) ||
      window.innerHeight || 0;
  }
  function fullscreenEnabled() {
    return !!document.fullscreenEnabled;
  }
  function isIOS() {
    return /iPhone|iPad|iPod/.test(navigator.userAgent || '');
  }
  function isFullscreen() {
    return !!document.fullscreenElement;
  }
  function requestFullscreen() {
    var e = document.documentElement;
    if (e.requestFullscreen) e.requestFullscreen();
  }
  function exitFullscreen() {
    if (document.exitFullscreen) document.exitFullscreen();
  }
  function notify() {
    window.dispatchEvent(new Event('cachoviewport'));
  }
  if (window.visualViewport) {
    window.visualViewport.addEventListener('resize', notify);
  }
  window.addEventListener('resize', notify);
  return {
    safeTop: safeTop,
    safeBottom: safeBottom,
    height: height,
    fullscreenEnabled: fullscreenEnabled,
    isIOS: isIOS,
    isFullscreen: isFullscreen,
    requestFullscreen: requestFullscreen,
    exitFullscreen: exitFullscreen,
  };
})();
