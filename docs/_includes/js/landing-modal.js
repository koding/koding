(function() {

  window.LANDING_UTILS = window.LANDING_UTILS || {};

  var showModal = document.querySelectorAll('.showModal'),
      youtube_id;

  LANDING_UTILS.modal = function(options) {
    options = options || {};

    [].forEach.call(showModal, function(el) {
      el.addEventListener('click', function(evt) {
        evt.preventDefault();

        var close, overlay, modal,
            content = options.content || "";

        overlay = document.createElement("div");
        overlay.className = "Overlay";

        modal = document.createElement('div');
        modal.className = "Modal";
        modal.id = "Modal";
        modal.innerHTML = '<div id="ModalBody"><a href="#" class="u-icon u-modalClose"></a>'+ content +'</div>';

        document.getElementsByTagName('body')[0].appendChild(overlay);
        document.getElementsByTagName('body')[0].appendChild(modal);

        close = modal.querySelector('.u-modalClose');

        if (options.onLoaded) {
          options.onLoaded(evt);
        }

        [].forEach.call([close, overlay], function(el) {
          el.addEventListener('click', function(e) {

            overlay.classList.add('out');
            modal.classList.add('out');

            setTimeout(function() {
              if (options.onDestroy) {
                options.onDestroy();
              }

              $(overlay).remove();
              $(modal).remove();
            }, 500);

          })
        });
      });
    })
  }

})();