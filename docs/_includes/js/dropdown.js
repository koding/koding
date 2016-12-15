(function() {
  var dropdown        = $('.Dropdown'),
      dropdownOptions = $('.Dropdown .Dropdown-options a');

  var initialize = function() {

    document.addEventListener('click', function(evt) {
      if (!$(evt.target).closest('.Dropdown') && document.find('.is-shown')) {
        [].forEach.call( dropdown, function(el) {
          if (el.classList.contains('is-shown')) {
            el.classList.remove('is-shown');
          }
        });
      }
    }, true);

    [].forEach.call( dropdown, function(el) {
      el.addEventListener('click', function(evt) {
        evt.preventDefault();

        if ($(evt.target).hasClass('disabled')) {
          return false;
        }

        if ($(this).hasClass('is-shown')) {
          $(this).removeClass('is-shown');
        } else {
          $(this).addClass('is-shown');
        }

      });
    });

    [].forEach.call( dropdownOptions, function(el) {
      el.addEventListener('click', function(evt) {
        evt.preventDefault();

        if ($(evt.target).hasClass('disabled')) {
          return false;
        }

        var dropdownLabel = $(evt.target).closest('.Dropdown').find('.Dropdown-selection')[0];

        dropdownLabel.innerHTML = this.innerHTML;
      }, false)
    });
  }

  initialize();
})();