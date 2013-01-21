/**
 * jQuery simple cookie plugin by Christopher Thorn:
 *        - ( a method "jQuery.cookie" accepting 3 parameters: cookieName [, cookieValue] [, daysTilExpiration] )
 *        - ( a method "jQuery.cookie" accepting 2 parameters: cookieName, {erase:true} )
 *        - ( a method "jQuery.cookie" accepting 1 parameter: cookieName; returning cookieValue )
 **/
;(function($) {
  
  function stringify(value) {
    if($.toJSON) {
      return $.toJSON(value);
    }
    else if(JSON && typeof JSON.stringify == 'function') {
      return JSON.stringify(value);
    }
    else {
      return value+'';
    }
  }
  
  function parse(value) {
    if($.evalJSON) {
      return $.evalJSON(value);
    }
    else if(JSON && typeof JSON.parse == 'function'){
      try {
        return JSON.parse(value);
      }
      catch (e) {
        return value;
      }
    }
    else try {
      return Function('return '+value)();
    } catch(e) {
      return null;
    }
  }
  
  function createCookie(name,value,days) {
    var expires;
    if (days) {
      var date = new Date();
      date.setTime(date.getTime()+(days*24*60*60*1000));
      expires = "; expires="+date.toGMTString();
    }
    else {
      expires = "";
    }
    document.cookie = name+"="+stringify(value)+expires+"; path=/";
  };
  
  function eraseCookie(name) {
    createCookie(name,"",-1);
  };
  
  function readCookie(name) {
    var nameEQ = name + "=";
    var ca = document.cookie.split(';');
    for(var i=0;i < ca.length;i++) {
      var c = ca[i];
      while(c.charAt(0)==' ') {
        c = c.substring(1,c.length);
      }
      if(c.indexOf(nameEQ) == 0) {
        return parse(c.substring(nameEQ.length,c.length));
      }
    }
    return null;
  };
  
  // public privileged jQuery.cookie (takes the three forms described above)
  $.cookie = function() {
    var a = arguments;
    if(a[1] && a[1].erase) {
      return eraseCookie(a[0]);
    } else if(a.length > 1) {
      return createCookie(a[0], a[1], a[2]);
    } else {
      return readCookie(a[0]);
    }
  };
}(jQuery));