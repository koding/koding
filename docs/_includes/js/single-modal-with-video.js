(function() {

  var showModal = document.querySelectorAll('.showModal'),
      youtube   = document.getElementsByTagName("iframe")[0],
      youtube_id;

  var initialize = function() {
    [].forEach.call(showModal, function(el) {
      el.addEventListener('click', function(evt) {
        evt.preventDefault();

        var close, overlay, modal;

        overlay = document.createElement("div");
        overlay.className = "Overlay";

        modal   = document.createElement('div');
        modal.className = "Modal";
        modal.innerHTML = '<a href="#" class="u-icon u-modalClose"></a>';
        modal.id = "Modal";

        close   = modal.querySelector('.u-modalClose');

        youtube_id = evt.currentTarget.getAttribute('data-youtube-id');
        modal.classList.add('Modal--withVideo');

        document.getElementsByTagName('body')[0].appendChild(overlay);
        document.getElementsByTagName('body')[0].appendChild(modal);
        overlay.classList.add('isShown');
        modal.classList.add('isShown');

        modal.innerHTML += '<div id="ModalBody"></div>';

        var player = new YT.Player('ModalBody', {
            width: 656,
            height: 369,
            videoId: youtube_id,
            events: {
              'onReady': onPlayerReady
            }
        });

        [].forEach.call([close, overlay], function(el) {
          el.addEventListener('click', function(e) {
            player.destroy();
            overlay.remove();
            modal.remove();

            if (youtube) {
              toggleVideo(youtube, 'hide');
            }
          })
        });
      });
    })
  }

  var onPlayerReady = function(event) {
    event.target.playVideo();
  }

  initialize();

})();