(function() {

	var showModal = document.querySelectorAll('.showModal'),
      youtube   = document.getElementsByTagName("iframe")[0];

	var initialize = function() {
    [].forEach.call(showModal, function(el) {
      el.addEventListener('click', function(e) {
        var close, overlay, modal;

        overlay = document.querySelector('.Overlay');
        modal   = document.querySelector('.Modal');
        close   = document.querySelector('.u-modalClose');

        overlay.classList.add('isShown');
        modal.classList.add('isShown');

        if (youtube) {
          toggleVideo(youtube, 'show');
        }

        [].forEach.call([close, overlay], function(el) {
          el.addEventListener('click', function(e) {
            overlay.classList.remove('isShown');
            modal.classList.remove('isShown');
            if (youtube) {
              toggleVideo(youtube, 'hide');
            }
          })
        });
      });
    })
	}
  initialize();

  var toggleVideo = function(youtube, state) {
    var iframe = youtube.contentWindow;
    var func = state == 'hide' ? 'pauseVideo' : 'playVideo';
    iframe.postMessage('{"event":"command","func":"' + func + '","args":""}', '*');
  }
})();