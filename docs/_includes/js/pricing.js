var ready = function($) {

  var $more = $("#Pricing-PriceSegments--more");
  var $hide = $("#Pricing-PriceSegments--close");
  var $show = $(".Pricing-PriceSegments--showMore");
  var $main = $("#Pricing-PriceSegments--devTeams");
  var $footnotes = $("#footnotes");
  $hide.click(function(event){
    event.stopPropagation();
    event.preventDefault();

    $more.removeClass('in')
    $main.removeClass('open')

    return false;
  });

  $show.click(function(event){
    event.stopPropagation();
    event.preventDefault();

    $more.toggleClass('in')
    $main.toggleClass('open')

    return false;
  });

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