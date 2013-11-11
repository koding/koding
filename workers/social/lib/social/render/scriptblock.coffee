module.exports = (options = {}, callback)->

  {intro} = options
  intro ?= no

  prefetcher = require '../prefetcher'
  encoder    = require 'htmlencode'

  options.intro   ?= no
  options.landing ?= no
  options.client or= {}
  options.client.context or= {}
  options.client.context.group or= "koding"


  prefetchedFeeds = {}
  {bongoModels, client, intro, landing} = options

  fetchMembersFromGraph = (cb)->
    return cb null, [] unless bongoModels
    {JGroup}  = bongoModels
    groupName = client?.context?.group or 'koding'
    JGroup.one slug: groupName, (err, group)->
      return cb null, [] if err
      group._fetchMembersFromGraph client, {}, cb

  fetchActivityFromGraph = (cb)->
    return cb null, [] unless bongoModels
    {CActivity} = bongoModels
    options = facets : "Everything"

    CActivity._fetchPublicActivityFeed client, options, (err, data)->
      return cb null, [] if err
      return cb null, data


  createHTML = ->
    replacer    = (k, v)-> if 'string' is typeof v then encoder.XSSEncode v else v
    encodedFeed = JSON.stringify prefetchedFeeds, replacer
    """
    <script>

      console.time("Framework loaded");
      console.time("Koding.com loaded");

      var _rollbarParams = {
        "server.environment": "production",
        "client.javascript.source_map_enabled": true,
        "client.javascript.code_version": "#{KONFIG.version}",
        "client.javascript.guess_uncaught_frames": true
      };
      _rollbarParams["notifier.snippet_version"] = "2"; var _rollbar=["713a5f6ab23c4ab0abc05494ef7bca55", _rollbarParams]; var _ratchet=_rollbar;
      (function(w,d){w.onerror=function(e,u,l){_rollbar.push({_t:'uncaught',e:e,u:u,l:l});};var i=function(){var s=d.createElement("script");var
      f=d.getElementsByTagName("script")[0];s.src="//d37gvrvc0wt4s1.cloudfront.net/js/1/rollbar.min.js";s.async=!0;
      f.parentNode.insertBefore(s,f);};if(w.addEventListener){w.addEventListener("load",i,!1);}else{w.attachEvent("onload",i);}})(window,document);
    </script>

    <script src="/js/require.js"></script>
    <script src="https://cdn.firebase.com/v0/firebase.js"></script>

    <script>
      require.config({baseUrl: "/js", waitSeconds:30});
      require(["order!/js/highlightjs/highlight.pack.js",
               "order!/js/kd.#{KONFIG.version}.js",
               #{if intro then '"order!/js/introapp.'+KONFIG.version+'.js",' else ''}
               "order!/js/koding.#{KONFIG.version}.js",
               #{if landing then '"order!/js/landingapp.'+KONFIG.version+'.js",' else ''}
              ]);
    </script>

    <script>(function(e,b){if(!b.__SV){var a,f,i,g;window.mixpanel=b;a=e.createElement("script");a.type="text/javascript";a.async=!0;a.src=("https:"===e.location.protocol?"https:":"http:")+'//cdn.mxpnl.com/libs/mixpanel-2.2.min.js';f=e.getElementsByTagName("script")[0];f.parentNode.insertBefore(a,f);b._i=[];b.init=function(a,e,d){function f(b,h){var a=h.split(".");2==a.length&&(b=b[a[0]],h=a[1]);b[h]=function(){b.push([h].concat(Array.prototype.slice.call(arguments,0)))}}var c=b;"undefined"!==
    typeof d?c=b[d]=[]:d="mixpanel";c.people=c.people||[];c.toString=function(b){var a="mixpanel";"mixpanel"!==d&&(a+="."+d);b||(a+=" (stub)");return a};c.people.toString=function(){return c.toString(1)+".people (stub)"};i="disable track track_pageview track_links track_forms register register_once alias unregister identify name_tag set_config people.set people.set_once people.increment people.append people.track_charge people.clear_charges people.delete_user".split(" ");for(g=0;g<i.length;g++)f(c,i[g]);
    b._i.push([a,e,d])};b.__SV=1.2}})(document,window.mixpanel||[]);
    mixpanel.init("#{KONFIG.mixpanel}");</script>

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

    <script src="https://www.dropbox.com/static/api/1/dropins.js" id="dropboxjs" data-app-key="yzye39livlcc21j"></script>
    <script>
      KD.prefetchedFeeds = #{encodedFeed};
    </script>
    """

  generateScript = ->
    html = createHTML()
    return callback null, html

  prefetcher options, (err, data)->
    # this is updating the prefetchedFeeds property
    prefetchedFeeds = data
    # we can generate html here
    return generateScript()
