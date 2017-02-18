var ready = function($) {

  var isSupported = false;
  var language = navigator.language || navigator.userLanguage
  languages   = [
    'ca', 'da', 'de', 'en', 'eu', 'fi',
    'fr', 'gd', 'he', 'id', 'is', 'it',
    'ja', 'ji', 'ko', 'nl', 'no', 'sv'
  ]

  for (i = 0, len = languages.length; i < len; i++) {
    supported = languages[i];
    if (language.indexOf(supported) == -1) {
      continue;
    }
    isSupported = true;
    break;
  }

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
