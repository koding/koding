(function() {

  window.LANDING_UTILS = window.LANDING_UTILS || {};

  var modalOptions = {}, player;

  modalOptions.onLoaded = function(clickEvent) {

    player = new YT.Player('ModalBody', {
        width: 656,
        height: 369,
        videoId: "DWRmEIbGqPQ",
        events: {
          'onReady': onPlayerReady
        }
    });

    document.querySelector('#Modal').classList.add('Modal--withVideo');
  }

  modalOptions.onDestroy = function() {
    player.destroy();
  }

  var onPlayerReady = function(event) {
    event.target.playVideo();
  }

  var modal = LANDING_UTILS.modal(modalOptions);

})();