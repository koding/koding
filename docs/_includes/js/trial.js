(function() {

  var modalOptions = {}, player,
      contact      = document.querySelectorAll('.contact'),
      Intercom     = Intercom || false;

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

  [].forEach.call(contact, function(el) {
    el.addEventListener('click', function(evt) {
      evt.preventDefault();

      if (Intercom) {
        Intercom('show')
      }
    });
  });

})();