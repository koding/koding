/*! Copyright (c) 2011 Sinan Yasar
 * Licensed under the MIT License (LICENSE.txt).
 */

(function($){

  $.fn.emit = function() {  
    
    var args,eventName;
    args = $.extend([],arguments);
    eventName = args[0];
    args = args.slice(1);
    this.trigger(eventName,args);

  };

})(jQuery);