# coffeelint: disable=cyclomatic_complexity
module.exports = (options = {}, callback) ->

  async     = require 'async'
  encoder   = require 'htmlencode'
  { argv }  = require 'optimist'
  _         = require 'lodash'

  options.client               or= {}
  options.client.context       or= {}
  options.client.context.group or= 'koding'
  options.client.connection    or= {}


  prefetchedFeeds     = null
  socialapidata       = null
  currentGroup        = null
  userMachines        = null
  userWorkspaces      = null
  userEnvironmentData = null
  userId              = null
  roles               = null
  permissions         = null

  { bongoModels, client, session } = options

  createHTML = ->
    if client.connection?.delegate?.profile?.nickname
      { impersonating, sessionToken, connection: { delegate } } = client
      { profile   : { nickname }, _id } = delegate

    replacer             = (k, v) -> if 'string' is typeof v then encoder.XSSEncode v else v
    { segment, client }  = KONFIG
    { siftScience }      = client.runtimeOptions
    config               = JSON.stringify client.runtimeOptions, replacer
    userRoles            = JSON.stringify roles, replacer
    userPermissions      = JSON.stringify permissions, replacer

    encodedSocialApiData = JSON.stringify socialapidata, replacer
    currentGroup         = JSON.stringify currentGroup, replacer
    userAccount          = JSON.stringify delegate, replacer
    userMachines         = JSON.stringify userMachines, replacer
    userWorkspaces       = JSON.stringify userWorkspaces, replacer
    userEnvironmentData  = JSON.stringify userEnvironmentData, replacer
    userId               = JSON.stringify userId, replacer


    # coffeelint: disable=space_operators
    # coffeelint: disable=no_unnecessary_double_quotes
    """
    <script type="text/javascript">
      !function(){var analytics=window.analytics=window.analytics||[];if(!analytics.initialize)if(analytics.invoked)window.console&&console.error&&console.error("Segment snippet included twice.");else{analytics.invoked=!0;analytics.methods=["trackSubmit","trackClick","trackLink","trackForm","pageview","identify","group","track","ready","alias","page","once","off","on"];analytics.factory=function(t){return function(){var e=Array.prototype.slice.call(arguments);e.unshift(t);analytics.push(e);return analytics}};for(var t=0;t<analytics.methods.length;t++){var e=analytics.methods[t];analytics[e]=analytics.factory(e)}analytics.load=function(t){var e=document.createElement("script");e.type="text/javascript";e.async=!0;e.src=("https:"===document.location.protocol?"https://":"http://")+"cdn.segment.com/analytics.js/v1/"+t+"/analytics.min.js";var n=document.getElementsByTagName("script")[0];n.parentNode.insertBefore(e,n)};analytics.SNIPPET_VERSION="3.0.1";
        analytics.load("#{segment}");
      }}();
    </script>

    <script>
      var _globals = {
        config: #{config},
        userId: #{userId},
        userAccount: #{userAccount},
        userMachines: #{userMachines},
        userWorkspaces: #{userWorkspaces},
        userRoles: #{userRoles},
        userPermissions: #{userPermissions},
        currentGroup: #{currentGroup},
        isLoggedInOnLoad: true,
        socialApiData: #{encodedSocialApiData},
        userEnvironmentData: #{userEnvironmentData}
      };
    </script>

    <script src="/a/p/p/#{KONFIG.version}/bundle.js"></script>

    <script>
      (function(d) {
        var config = {
          kitId: 'rbd0tum',
          scriptTimeout: 3000
        },
        h=d.documentElement,t=setTimeout(function(){h.className=h.className.replace(/\bwf-loading\b/g,"")+" wf-inactive";},config.scriptTimeout),tk=d.createElement("script"),f=false,s=d.getElementsByTagName("script")[0],a;h.className+=" wf-loading";tk.src='//use.typekit.net/'+config.kitId+'.js';tk.async=true;tk.onload=tk.onreadystatechange=function(){a=this.readyState;if(f||a&&a!="complete"&&a!="loaded")return;f=true;clearTimeout(t);try{Typekit.load(config)}catch(e){}};s.parentNode.insertBefore(tk,s)
      })(document);
    </script>

    #{if not impersonating then "
      <script type='text/javascript'>
        var _user_id = '#{nickname}'; var _session_id = '#{sessionToken}'; var _sift = _sift || []; _sift.push(['_setAccount', '#{siftScience}']); _sift.push(['_setUserId', _user_id]); _sift.push(['_setSessionId', _session_id]); _sift.push(['_trackPageview']); (function() { function ls() { var e = document.createElement('script'); e.type = 'text/javascript'; e.async = true; e.src = ('https:' == document.location.protocol ? 'https://' : 'http://') + 'cdn.siftscience.com/s.js'; var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(e, s); } if (window.attachEvent) { window.attachEvent('onload', ls); } else { window.addEventListener('load', ls, false); } })();</script>
    " else '' }

    #{if argv.t then "<script src=\"/a/js/tests.js\"></script>" else ''}

    <script>
      (function(h,o,t,j,a,r){
        h.hj=h.hj||function(){(h.hj.q=h.hj.q||[]).push(arguments)};
        h._hjSettings={hjid:156048,hjsv:5};
        a=o.getElementsByTagName('head')[0];
        r=o.createElement('script');r.async=1;
        r.src=t+h._hjSettings.hjid+j+h._hjSettings.hjsv;
        a.appendChild(r);
      })(window,document,'//static.hotjar.com/c/hotjar-','.js?sv=');
    </script>
    """

  queue = [

    (fin) ->
       socialApiCacheFn = require '../cache/socialapi'
       socialApiCacheFn options, (err, data) ->
         console.error 'could not get prefetched data', err  if err
         socialapidata = data
         fin()

    (fin) ->
      groupName = session?.groupName or 'koding'

      # due to some reason, I suspect JSON.stringify somewhere, undefined
      # is stringified as 'undefined', this check makes sure, it defaults
      # to 'koding', ie default group in that case
      if groupName is 'undefined' then groupName = 'koding'

      bongoModels.JGroup.one { slug : groupName }, (err, group) ->
        console.log err  if err

        currentGroup = group  if group

        fin()

    (fin) ->

      { delegate : account } = client.connection
      account.fetchMyPermissionsAndRoles client, (err, res) ->

        console.log err  if err

        roles       = res.roles
        permissions = res.permissions

        fin()

    (fin) ->
      bongoModels.JWorkspace.fetchByMachines$ client, (err, workspaces) ->
        console.log err  if err
        userWorkspaces = workspaces or []
        fin()

    (fin) ->
      bongoModels.JMachine.some$ client, {}, (err, machines) ->
        console.log err  if err
        userMachines = machines or []
        fin()

    (fin) ->
      bongoModels.Sidebar.fetchEnvironment client, (err, data) ->
        userEnvironmentData = data
        fin()

    (fin) ->
      client.connection.delegate.fetchUser (err, user) ->
        if err
          console.error '[scriptblock] user not found', err
          return fin()

        if user then userId = user.getId()
        else console.error '[scriptblock] user not found', err
        fin()
  ]

  async.parallel queue, -> callback null, createHTML(), socialapidata
