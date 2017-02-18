var userCounts = {
  "1-10" : "$49<cite>.97</cite>",
  "11-50" : "$39<cite>.82</cite>",
  "51-100" : "$34<cite>.93</cite>"
}
var ready = function($) {

  var $more = $("#Pricing-PriceSegments--more");
  var $hide = $("#Pricing-PriceSegments--close");
  var $show = $(".Pricing-PriceSegments--showMore");
  var $main = $("#Pricing-PriceSegments--kodingLite");
  var $footnotes = $("#footnotes");
  var dropdownOptions = $('.Dropdown .Dropdown-options a');

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

  dropdownOptions.click(function() {
    var $self = $(this);
    var val    = $self.attr('attr-value');
    var $price = $self.closest('.Pricing-PriceSegments--priceSection').find('.first-line');
    $price.html(userCounts[val]);
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