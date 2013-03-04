var _rollbarParams = {"server.environment": "production"};
_rollbarParams["notifier.snippet_version"] = "2"; var _rollbar=["3bb27b1126774f66b34af9d51b362be5", _rollbarParams]; var _ratchet=_rollbar;
(function(w,d){w.onerror=function(e,u,l){_rollbar.push({_t:'uncaught',e:e,u:u,l:l});};var i=function(){var s=d.createElement("script");var f=d.getElementsByTagName("script")[0];s.src="//d37gvrvc0wt4s1.cloudfront.net/js/1/rollbar.min.js";s.async=!0; f.parentNode.insertBefore(s,f);};if(w.addEventListener){w.addEventListener("load",i,!1);}else{w.attachEvent("onload",i);}})(window,document);
