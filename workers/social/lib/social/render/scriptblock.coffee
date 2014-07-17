module.exports = (options = {}, callback)->
  encoder = require 'htmlencode'

  options.client               or= {}
  options.client.context       or= {}
  options.client.context.group or= "koding"
  options.client.connection    or= {}

  {argv} = require 'optimist'

  prefetchedFeeds  = null
  customPartial    = null
  campaignData     = null
  currentGroup     = null
  usePremiumBroker = no

  {bongoModels, client, slug} = options

  createHTML = ->
    if client.connection?.delegate?.profile?.nickname
      {connection: {delegate}} = client
      {profile   : {nickname}, _id} = delegate

    replacer             = (k, v)-> if 'string' is typeof v then encoder.XSSEncode v else v
    encodedFeed          = JSON.stringify prefetchedFeeds, replacer
    encodedCampaignData  = JSON.stringify campaignData, replacer
    encodedCustomPartial = JSON.stringify customPartial, replacer
    currentGroup         = JSON.stringify currentGroup
    userAccount          = JSON.stringify delegate

    usePremiumBroker = usePremiumBroker or options.client.context.group isnt "koding"

    {rollbar, version, environment} = KONFIG

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

    <script>KD.config.usePremiumBroker=#{usePremiumBroker}</script>
    <script>KD.customPartial=#{encodedCustomPartial}</script>
    <script>KD.campaignData=#{encodedCampaignData}</script>
    <script src='/a/js/kd.libs.js?#{KONFIG.version}'></script>
    <script src='/a/js/kd.js?#{KONFIG.version}'></script>
    <script src='/a/js/koding.js?#{KONFIG.version}'></script>
    <script>
    KD.utils.defer(function () {
      KD.currentGroup = KD.remote.revive(#{currentGroup});
      KD.userAccount = KD.remote.revive(#{userAccount});
    });
    </script>
    <script>KD.prefetchedFeeds=#{encodedFeed};</script>

    <!-- Google Analytics -->
    <script>
    (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
    (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
    m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
    })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

    ga('create', 'UA-6520910-8', 'auto');

    // we hook onto KD router 'RouteInfoHandled' to send page views instead,
    // see analytic.coffee
    //ga('send', 'pageview');

    </script>
    <!-- End Google Analytics -->

    #{if argv.t then "<script src=\"/a/js/tests.js\"></script>" else ''}

    <!-- Facebook Conversion Code for FB-Koding Registrations -->
    <script type="text/javascript">
      var fb_param = {};
      fb_param.pixel_id = '6011653749578';
      fb_param.value = '0.01';
      fb_param.currency = 'USD';
      (function(){
      var fpw = document.createElement('script');
      fpw.async = true;
      fpw.src = '//connect.facebook.net/en_US/fp.js';
      var ref = document.getElementsByTagName('script')[0];
      ref.parentNode.insertBefore(fpw, ref);
      })();
    </script>
    <noscript>
      <img height="1" width="1" alt="" style="display:none" src="https://www.facebook.com/offsite_event.php?id=6011653749578&amp;value=0.01&amp;currency=USD" />
    </noscript>

    <script type="text/javascript" src="https://www.google.com/recaptcha/api/js/recaptcha_ajax.js"></script>
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
            currentGroup = group
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
