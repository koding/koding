module.exports =

  # <!-- twitter -->
  # <script src="//platform.twitter.com/oct.js" type="text/javascript"></script>
  # <script type="text/javascript">twttr.conversion.trackPid('l50ku');</script>
  # <noscript>
  #   <img height="1" width="1" style="display:none;" alt="" src="https://analytics.twitter.com/i/adsct?txn_id=l50ku&p_id=Twitter" />
  #   <img height="1" width="1" style="display:none;" alt="" src="//t.co/i/adsct?txn_id=l50ku&p_id=Twitter" />
  # </noscript>

  # forcing noscript option
  # bc: https://twittercommunity.com/t/async-widgets-js-loader-is-not-compatible-with-oct-js-initialize-different-twttr-object-missing-ready/21522
  # - SY
  """
  <!-- twitter -->
  <img height="1" width="1" style="display:none;" alt="" src="https://analytics.twitter.com/i/adsct?txn_id=l50ku&p_id=Twitter" />
  <img height="1" width="1" style="display:none;" alt="" src="//t.co/i/adsct?txn_id=l50ku&p_id=Twitter" />

  <!-- facebook -->
  <script>
    (function() {
      var _fbq = window._fbq || (window._fbq = []);
      if (!_fbq.loaded) {
        var fbds = document.createElement('script');
        fbds.async = true;
        fbds.src = '//connect.facebook.net/en_US/fbds.js';
        var s = document.getElementsByTagName('script')[0];
        s.parentNode.insertBefore(fbds, s);
        _fbq.loaded = true;
      }
    })();
    window._fbq = window._fbq || [];
    window._fbq.push(['track', '6021968268835', {'value':'0.00','currency':'USD'}]);
  </script>
  <noscript>
    <img height="1" width="1" alt="" style="display:none" src="https://www.facebook.com/tr?ev=6021968268835&amp;cd[value]=0.00&amp;cd[currency]=USD&amp;noscript=1" />
  </noscript>
  <!-- addthis -->
  <script type="text/javascript" src="//s7.addthis.com/js/300/addthis_widget.js#pubid=ra-5446b4f213717e36" async></script>
  """
