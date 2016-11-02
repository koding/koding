(function() {

  var showModal = document.querySelectorAll('.showModal'),
      youtube   = document.getElementsByTagName("iframe")[0],
      youtube_id;

  var initialize = function() {
    [].forEach.call(showModal, function(el) {
      el.addEventListener('click', function(e) {
        var close, overlay, modal;

        overlay = document.createElement("div");
        overlay.className = "Overlay";

        modal   = document.createElement('div');
        modal.className = "Modal";
        modal.innerHTML = '<a href="#" class="u-icon u-modalClose"></a>';

        close   = modal.querySelector('.u-modalClose');

        youtube_id = e.currentTarget.getAttribute('data-youtube-id');
        modal.innerHTML += '<iframe width="656" height="369" src="https://www.youtube.com/embed/' + youtube_id + '?enablejsapi=1"></iframe>';

        document.getElementsByTagName('body')[0].appendChild(overlay);
        document.getElementsByTagName('body')[0].appendChild(modal);
        overlay.classList.add('isShown');
        modal.classList.add('isShown');

        youtube = document.getElementsByTagName("iframe")[0];

        if (youtube) {
          toggleVideo(youtube, 'show');
        }

        [].forEach.call([close, overlay], function(el) {
          el.addEventListener('click', function(e) {
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

  var toggleVideo = function(youtube, state) {
    var iframe = youtube.contentWindow;
    var func = state == 'hide' ? 'pauseVideo' : 'playVideo';
    iframe.postMessage('{"event":"command","func":"' + func + '","args":""}', '*');
  }

  initialize();

})();