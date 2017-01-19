var ready = function($) {

  var $footnotes = $("#footnotes");

  $('.contact').click(function(event){
    event.stopPropagation();
    event.preventDefault();

    if (Intercom) {
      Intercom('show')
    }

    return false;
  });

  $footnotes.find('h3').click(function() {
    var $self = $(this);
    $self.next().toggle();
  });

  if (/footnotes/.test(document.location.hash)) {
    $footnotes.find('h3').next().show();
  }

}

$(document).ready(ready);