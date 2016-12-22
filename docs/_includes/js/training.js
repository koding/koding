(function() {

  var modalOptions = {}, player;

  modalOptions.onLoaded = function(clickEvent) {
    var youtube_id = clickEvent.currentTarget.getAttribute('data-youtube-id');

    player = new YT.Player('ModalBody', {
        width: 656,
        height: 369,
        videoId: youtube_id,
        events: {
          'onReady': onPlayerReady
        }
    });

   $('#Modal').addClass('Modal--withVideo');
  }

  modalOptions.onDestroy = function() {
    player.destroy();
  }

  var onPlayerReady = function(event) {
    event.target.playVideo();
  }

  var modal = LANDING_UTILS.modal(modalOptions);

})();