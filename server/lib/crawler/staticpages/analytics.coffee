{argv} = require 'optimist'
config = require('koding-config-manager').load("main.#{argv.c}")
{rollbar, version} = config

module.exports = ->

  """
    <!-- GOOGLE ANALYTICS -->
    <script>
      var _gaq = _gaq || [];
      _gaq.push(['_setAccount', 'UA-6520910-8']);
      _gaq.push(['_setDomainName', 'koding.com']);
      _gaq.push(['_trackPageview']);
      (function() {
        var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
        ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
        var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
      })();
    </script>

    <!-- ROLLBAR -->
    <script>
      var startTime = new Date().getTime();
      var _rollbarParams = {
        "server.environment": "production",
        "client.javascript.source_map_enabled": true,
        "client.javascript.code_version": "#{version}",
        "client.javascript.guess_uncaught_frames": true,
        checkIgnore: function(msg, file, line, col, err) {
          if ((new Date().getTime() - startTime) > 1000*60*60) {
            // ignore errors after the page has been open for 1hr
            return true;
          }
          return false;
        }
      };
      _rollbarParams["notifier.snippet_version"] = "2"; var _rollbar=["#{rollbar}", _rollbarParams]; var _ratchet=_rollbar;
      (function(w,d){w.onerror=function(e,u,l){_rollbar.push({_t:'uncaught',e:e,u:u,l:l});};var i=function(){var s=d.createElement("script");var
      f=d.getElementsByTagName("script")[0];s.src="//d37gvrvc0wt4s1.cloudfront.net/js/1/rollbar.min.js";s.async=!0;
      f.parentNode.insertBefore(s,f);};if(w.addEventListener){w.addEventListener("load",i,!1);}else{w.attachEvent("onload",i);}})(window,document);
    </script>
"""
