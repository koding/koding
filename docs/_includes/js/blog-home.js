var ready = function($){
  var $authors = $('.BlogPost-Meta figure');
  $authors.each(function(index){
    var email = $(this).attr('alt'),
        $img  = $(this).find('img'),
        default_img = encodeURIComponent("//koding-cdn.s3.amazonaws.com/blog-default-user-avatar.png"),
        gravatar_path = "//gravatar.com/avatar/";

    var src = gravatar_path + md5(email) + "?d=" + default_img + "&s=100";
    $img.attr('src', src);
    $(this).attr('alt', '');
  });
}

$(document).ready(ready);