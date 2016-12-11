document.addEventListener('scroll', function(event){

  var header = document.querySelectorAll('header.Homepage-Header').item(0);
  if (!header) return null;

  if (document.body.scrollTop < 100) {
    if (!document.body.classList.contains('StickyHeader')) {
      return null;
    }
    document.body.classList.remove('StickyHeader');
  } else if (document.body.scrollTop < 710) {
    if (!document.body.classList.contains('StickyHeader')) {
      return null;
    }
    document.body.classList.remove('in');
    setTimeout(function(){
      document.body.classList.remove('StickyHeader');
    }, 400);
  } else {

    if (document.body.classList.contains('StickyHeader')) {
      return null;
    }
    document.body.classList.add('StickyHeader');
    setTimeout(function(){
      document.body.classList.add('in');
    }, 400);
  }

});