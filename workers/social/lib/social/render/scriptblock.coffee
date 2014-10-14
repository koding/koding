{dash} = require 'bongo'

module.exports = (options = {}, callback)->
  encoder = require 'htmlencode'

  options.client               or= {}
  options.client.context       or= {}
  options.client.context.group or= "koding"
  options.client.connection    or= {}

  {argv} = require 'optimist'

  prefetchedFeeds  = null
  socialapidata    = null
  currentGroup     = null
  userMachines     = null
  userWorkspaces   = null
  usePremiumBroker = no

  {bongoModels, client, slug} = options

  createHTML = ->
    if client.connection?.delegate?.profile?.nickname
      {sessionToken, connection: {delegate}} = client
      {profile   : {nickname}, _id} = delegate

    replacer             = (k, v)-> if 'string' is typeof v then encoder.XSSEncode v else v
    encodedSocialApiData = JSON.stringify socialapidata, replacer
    currentGroup         = JSON.stringify currentGroup
    userAccount          = JSON.stringify delegate
    userMachines         = JSON.stringify userMachines
    userWorkspaces       = JSON.stringify userWorkspaces

    usePremiumBroker = usePremiumBroker or options.client.context.group isnt "koding"

    {rollbar, version, environment, segment, client} = KONFIG
    {siftScience} = client.runtimeOptions

    """
    <!-- SEGMENT.IO -->
    <script type="text/javascript">
      window.analytics||(window.analytics=[]),window.analytics.methods=["identify","track","trackLink","trackForm","trackClick","trackSubmit","page","pageview","ab","alias","ready","group","on","once","off"],window.analytics.factory=function(t){return function(){var a=Array.prototype.slice.call(arguments);return a.unshift(t),window.analytics.push(a),window.analytics}};for(var i=0;window.analytics.methods.length>i;i++){var method=window.analytics.methods[i];window.analytics[method]=window.analytics.factory(method)}window.analytics.load=function(t){var a=document.createElement("script");a.type="text/javascript",a.async=!0,a.src=("https:"===document.location.protocol?"https://":"http://")+"d2dq2ahtl5zl1z.cloudfront.net/analytics.js/v1/"+t+"/analytics.min.js";var n=document.getElementsByTagName("script")[0];n.parentNode.insertBefore(a,n)},window.analytics.SNIPPET_VERSION="2.0.8",
      window.analytics.load("#{segment}");
      window.analytics.page();
    </script>

    <script>KD.config.usePremiumBroker=#{usePremiumBroker}</script>
    <script>KD.socialApiData=#{encodedSocialApiData}</script>
    <script>KD.userMachines=#{userMachines}</script>
    <script>KD.userWorkspaces=#{userWorkspaces}</script>
    <script>KD.userAccount=#{userAccount}</script>
    <script>KD.currentGroup=#{currentGroup}</script>
    <script src='/a/js/kd.libs.js?#{KONFIG.version}'></script>
    <script src='/a/js/kd.js?#{KONFIG.version}'></script>
    <script src='/a/js/koding.js?#{KONFIG.version}'></script>
    <script>
      KD.utils.defer(function () {
        KD.currentGroup = KD.remote.revive(KD.currentGroup);
        KD.userAccount = KD.remote.revive(KD.userAccount);
      });
    </script>

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

    <script type="text/javascript">
      var _user_id = '#{nickname}'; var _session_id = '#{sessionToken}'; var _sift = _sift || []; _sift.push(['_setAccount', '#{siftScience}']); _sift.push(['_setUserId', _user_id]); _sift.push(['_setSessionId', _session_id]); _sift.push(['_trackPageview']); (function() { function ls() { var e = document.createElement('script'); e.type = 'text/javascript'; e.async = true; e.src = ('https:' == document.location.protocol ? 'https://' : 'http://') + 'cdn.siftscience.com/s.js'; var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(e, s); } if (window.attachEvent) { window.attachEvent('onload', ls); } else { window.addEventListener('load', ls, false); } })();
    </script>

    #{if argv.t then "<script src=\"/a/js/tests.js\"></script>" else ''}
    """

  selector =
    partialType : "HOME"

  if options.isCustomPreview
    selector.isPreview = yes
  else
    selector.isActive  = yes

  queue = [
    ->
      socialApiCacheFn = require '../cache/socialapi'
      socialApiCacheFn options, (err, data)->
        socialapidata = data
        queue.fin()
    ->
      bongoModels.JGroup.one {slug : slug or 'koding'}, (err, group) ->
        console.log err if err
        if group
          currentGroup = group

        queue.fin()
    ->
      bongoModels.JWorkspace.fetch client, {}, (err, workspaces) ->
        console.log err  if err
        userWorkspaces = workspaces or []
        queue.fin()
    ->
      bongoModels.JMachine.some$ client, {}, (err, machines) ->
        console.log err  if err
        userMachines = machines or []
        queue.fin()
  ]

  dash queue, -> callback null, createHTML()
