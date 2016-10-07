if (!window.KODING_UTILS) window.KODING_UTILS = {};

KODING_UTILS.submitForm = function(options) {

  $('#subscribe-to-newsletter input[name=Field3]').val(document.referrer);

  $('#subscribe-to-newsletter').submit(function(event){
    event.preventDefault();
    var $form = $(this);

    {% if jekyll.environment == 'production' %}
    var hostname = 'https://koding.com',
    {% else %}
    var hostname = 'http://dev.koding.com:8090',
    {% endif %}
        FORM_URL = hostname + '/-/wufoo/submit/z5z2m7x0ln3g44',
        data = $(this).serializeArray();

    $.ajax({
      type: 'POST',
      url: FORM_URL,
      data: data,
      success: function() {
        $form.addClass('hidden').prev().removeClass('hidden');
      },
      error: function(arg) {
        var responseText = arg.responseText;
        try {
          responseText = JSON.parse(responseText)
        }
        catch(e) {
          console.log('couldn\'t parse the response')
        }
        console.log(responseText);
      }
    });
    return false;
  });
}

$(document).ready(ready);
