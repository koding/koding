(function($) {

$.fn.switch = function(settings) {
  settings = settings || {};
  var o = {
    
    'anim'          : settings.anim           || true,
    'duration'      : settings.duration       || 150,
    'image_height'  : settings.image_height   || 140,
    'image_width'   : settings.image_width    || 59,
    'total_frames'  : settings.total_frames   || 7,
    'change'        : settings.change         || function(){},
    'disabledClick' : settings.disabledClick  || function(){}
  };
  
  if (settings) $.extend(o, settings);
  
  this.each(function() {
    
    var $input = $(this);
    var $switch = $('<span class="jquery-switch"></span>');
    var state = $input.is(':checked');
    var cssClass = "switchtrue";

    if (!state) {
      cssClass = "switchfalse";
      $switch.addClass(cssClass);
      $switch.css("background-position", "left -"+(o.image_height-o.image_height/o.total_frames)+"px"); 
    }else{
      $switch.addClass(cssClass);
    }

    $(this).data('state', state);
    $input.hide();
    $input.parent().append($switch);

    if ($input.is(':disabled'))
    {
      if (state){ 
        $switch.css("background-position", "left -"+o.image_height+"px");
      }else{
        $switch.css("background-position", "left -"+(o.image_height+o.image_height/o.total_frames)+"px")
      }
      $switch.bind('click', function() {
        o.disabledClick.call(this,$input,state);
      }); 
    }
    else
    {
      var is_animated = false;
      $switch.bind('click', function() {
    
        var $that = $(this);
        if ( $that.hasClass('switchfalse') && !is_animated)
        {
          if(o.anim){
            var a = -1*(o.image_height-o.image_height/o.total_frames);
            var i = 1;        
            var t = setInterval(function() {
              is_animated = true;
              a += o.image_height/o.total_frames;
              $that.css("background-position", "left "+a+"px");
              if (i === o.total_frames-1) 
              {
                $that.removeClass('switchfalse').addClass('switchtrue');
                $input.attr("checked",true);
                clearInterval(t);
                is_animated = false;
                o.change.call($input,true);
              };
              i++;
            },o.duration/o.total_frames);
          }else{
            $that.removeClass('switchfalse').addClass('switchtrue');
            $input.attr("checked",true);
          }
        }
        else if($that.hasClass('switchtrue') && !is_animated)
        {
          if(o.anim){
            var a = 0;
            $that.removeClass('switchtrue').addClass('switchfalse');
            var i = 1;        
            var t = setInterval(function() {
              is_animated = true;
              a -= o.image_height/o.total_frames;
              $that.css("background-position", "left "+a+"px");
              if (i === o.total_frames-1)
              {
                $that.removeClass('switchtrue').addClass('switchfalse');
                $input.attr("checked",false);
                clearInterval(t);
                is_animated = false;
                o.change.call($input,false);
              } 
              i++;
            },o.duration/o.total_frames);
          }else{
            $that.removeClass('switchtrue').addClass('switchfalse');
            $input.attr("checked",false);
          }
        }
      });   
    }

  });

  return this;
};

})(jQuery);