var ready = function($) {

  var isSupported = false;
  var utils = window.KODING_UTILS;

  utils.requests.intercomSupport().then(function(isSupported_){
    isSupported = isSupported_
  });

  $('.contact').click(function(event){

    if (Intercom && isSupported) {
      Intercom('show')
      event.stopPropagation();
      event.preventDefault();

      return false;
    }

    return true;
  });
}

$(document).ready(ready);
