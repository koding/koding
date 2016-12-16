document.addEventListener('scroll', function(event){

  var header = document.querySelectorAll('header.Homepage-Header').item(0);
  if (!header) return null;

  var scrollTop = window.scrollY || $('html, body').scrollTop();

  if (scrollTop < 100) {
    if (!$(document.body).hasClass('StickyHeader')) {
      return null;
    }
    $(document.body).removeClass('StickyHeader');
  } else if (scrollTop < 710) {
    if (!$(document.body).hasClass('StickyHeader')) {
      return null;
    }
    $(document.body).removeClass('in');
    setTimeout(function(){
      $(document.body).removeClass('StickyHeader');
    }, 400);
  } else {

    if ($(document.body).hasClass('StickyHeader')) {
      return null;
    }
    $(document.body).addClass('StickyHeader');
    setTimeout(function(){
      $(document.body).addClass('in');
    }, 400);
  }

});