module.exports = (options = {}, callback)->
  encoder = require 'htmlencode'

  options.intro                 ?= no
  options.landing               ?= no
  options.client               or= {}
  options.client.context       or= {}
  options.client.context.group or= "koding"
  options.client.connection    or= {}

  {argv} = require 'optimist'

  prefetchedFeeds  = {}
  customPartial    = {}
  campaignData     = {}
  currentGroup     = {}
  usePremiumBroker = no

  {bongoModels, client, intro, landing, slug} = options

  createHTML = ->
    replacer             = (k, v)-> if 'string' is typeof v then encoder.XSSEncode v else v
    encodedFeed          = JSON.stringify prefetchedFeeds, replacer
    encodedCampaignData  = JSON.stringify campaignData, replacer
    encodedCustomPartial = JSON.stringify customPartial, replacer
    currentGroup         = JSON.stringify currentGroup, replacer
    landingOptions       = page : landing

    usePremiumBroker = usePremiumBroker or options.client.context.group isnt "koding"
    landingOptions =
      page         : landing

    if client.connection?.delegate?.profile?.nickname
      {connection: {delegate}} = client
      {profile   : {nickname}} = delegate
      landingOptions.username  = nickname if delegate.type is "registered"


    landingOptions = JSON.stringify landingOptions
    """
    <script>
      console.time("Framework loaded");
      console.time("Koding.com loaded");
    </script>

    <!-- SEGMENT.IO -->
    <script type="text/javascript">
      window.analytics||(window.analytics=[]),window.analytics.methods=["identify","track","trackLink","trackForm","trackClick","trackSubmit","page","pageview","ab","alias","ready","group","on","once","off"],window.analytics.factory=function(t){return function(){var a=Array.prototype.slice.call(arguments);return a.unshift(t),window.analytics.push(a),window.analytics}};for(var i=0;window.analytics.methods.length>i;i++){var method=window.analytics.methods[i];window.analytics[method]=window.analytics.factory(method)}window.analytics.load=function(t){var a=document.createElement("script");a.type="text/javascript",a.async=!0,a.src=("https:"===document.location.protocol?"https://":"http://")+"d2dq2ahtl5zl1z.cloudfront.net/analytics.js/v1/"+t+"/analytics.min.js";var n=document.getElementsByTagName("script")[0];n.parentNode.insertBefore(a,n)},window.analytics.SNIPPET_VERSION="2.0.8",
      window.analytics.load("3crxx7q648");
      window.analytics.page();
    </script>

    <!-- HEAP ANALYTICS -->
    <script type="text/javascript">var heap=heap||[];heap.load=function(a){window._heapid=a;var b=document.createElement("script");b.type="text/javascript",b.async=!0,b.src=("https:"===document.location.protocol?"https:":"http:")+"//cdn.heapanalytics.com/js/heap.js";var c=document.getElementsByTagName("script")[0];c.parentNode.insertBefore(b,c);var d=function(a){return function(){heap.push([a].concat(Array.prototype.slice.call(arguments,0)))}},e=["identify","track"];for(var f=0;f<e.length;f++)heap[e[f]]=d(e[f])};heap.load("112304216");</script>

    <script>KD.config.usePremiumBroker=#{usePremiumBroker}</script>
    <script>KD.customPartial=#{encodedCustomPartial}</script>
    <script>KD.campaignData=#{encodedCampaignData}</script>
    <script src='/a/js/kd.#{KONFIG.version}.js'></script>
    #{if intro then "<script src='/a/js/introapp.#{ KONFIG.version }.js'></script>" else ''}
    <script>KD.currentGroup=#{currentGroup};</script>
    <script src='/a/js/koding.#{KONFIG.version}.js'></script>
    #{if landing then "<script src='/a/js/landingapp.#{ KONFIG.version }.js'></script>" else ''}
    <script>KD.prefetchedFeeds=#{encodedFeed};</script>


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
        "client.javascript.code_version": "#{KONFIG.version}",
        "client.javascript.guess_uncaught_frames": true,
        checkIgnore: function(msg, file, line, col, err) {
          if ((new Date().getTime() - startTime) > 1000*60*60) {
            // ignore errors after the page has been open for 1hr
            return true;
          }
          return false;
        }
      };
      _rollbarParams["notifier.snippet_version"] = "2"; var _rollbar=["#{KONFIG.rollbar}", _rollbarParams]; var _ratchet=_rollbar;
      (function(w,d){w.onerror=function(e,u,l){_rollbar.push({_t:'uncaught',e:e,u:u,l:l});};var i=function(){var s=d.createElement("script");var
      f=d.getElementsByTagName("script")[0];s.src="//d37gvrvc0wt4s1.cloudfront.net/js/1/rollbar.min.js";s.async=!0;
      f.parentNode.insertBefore(s,f);};if(w.addEventListener){w.addEventListener("load",i,!1);}else{w.attachEvent("onload",i);}})(window,document);
    </script>
    #{if argv.t then "<script src=\"/a/js/tests.js\"></script>" else ''}
    """

  kallback = ->
    {delegate} = options.client.connection

    if 'function' is typeof delegate?.fetchSubscriptions
      selector = {}
      fetchOptions = targetOptions: selector :{ tags: $nin: ["nosync"] }

      delegate.fetchSubscriptions selector, fetchOptions, (err, subscriptions)->
        if subscriptions and subscriptions.length
          usePremiumBroker = yes
        callback null, createHTML()
    else
      callback null, createHTML()

  generateScript = ->
    selector =
      partialType : "HOME"

    if options.isCustomPreview
      selector.isPreview = yes
    else
      selector.isActive  = yes

    # add custom partials into body
    bongoModels.JCustomPartials.one selector, (err, partial)->
      customPartial = partial.data  if not err and partial

      bongoModels.JGroup.one {slug : slug or 'koding'}, (err, group) ->
        console.log err if err
        # add custom partial into referral campaign
        bongoModels.JReferralCampaign.one {isActive:yes}, (err, campaignData_)->
          if not err and campaignData_ and campaignData_.data
            campaignData = campaignData_.data
          if group
            currentGroup =
              logo       : group.customize?.logo or ""
              coverPhoto : group.customize?.coverPhoto or ""
              id         : group.getId()
          kallback()



  {delegate} = options.client.connection
  # if user is exempt or super-admin do not cache his/her result set
  return generateScript()  if delegate and delegate.checkFlag ['super-admin', 'exempt']

  Cache  = require '../cache/main'
  feedFn = require '../cache/feed'

  getCacheKey =-> return "scriptblock#{options.client.context.group}"

  Cache.fetch getCacheKey(), feedFn, options, (err, data)->
    prefetchedFeeds = data    # this is updating the prefetchedFeeds property
    return generateScript()   # we can generate html here
