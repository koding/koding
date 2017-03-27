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
  currentGroup        = null
  userMachines        = null
  userStacks          = null
  userId              = null
  userEmail           = null
  userStatus          = null
  roles               = null
  permissions         = null
  combinedStorage     = null

  { bongoModels, client, session } = options

  createHTML = ->
    if client.connection?.delegate?.profile?.nickname
      { impersonating, sessionToken, connection: { delegate } } = client
      { profile   : { nickname }, _id } = delegate

    replacer             = (k, v) -> if 'string' is typeof v then encoder.XSSEncode v else v
    { segment, client }  = KONFIG
    config               = JSON.stringify client.runtimeOptions, replacer
    userRoles            = JSON.stringify roles, replacer
    userPermissions      = JSON.stringify permissions, replacer

    currentGroup         = JSON.stringify currentGroup, replacer
    userAccount          = JSON.stringify delegate, replacer
    combinedStorage      = JSON.stringify combinedStorage, replacer
    userMachines         = JSON.stringify userMachines, replacer
    userStacks           = JSON.stringify userStacks, replacer
    userId               = JSON.stringify userId, replacer
    userEmail            = JSON.stringify userEmail, replacer
    userStatus           = JSON.stringify userStatus, replacer

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
        userEmail: #{userEmail},
        userStatus: #{userStatus},
        userAccount: #{userAccount},
        userMachines: #{userMachines},
        userStacks: #{userStacks},
        combinedStorage: #{combinedStorage},
        userRoles: #{userRoles},
        userPermissions: #{userPermissions},
        currentGroup: #{currentGroup},
        isLoggedInOnLoad: true
      };
    </script>

    <script src="/a/p/p/#{KONFIG._CLIENTVERSION}/bundle.vendor.js"></script>
    <script src="/a/p/p/#{KONFIG._CLIENTVERSION}/bundle.main.js"></script>

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
        if err
          console.log "error while fetching fetchMyPermissionsAndRoles", err
          return fin()

        roles       = res.roles
        permissions = res.permissions

        fin()

    (fin) ->
      { delegate : account } = client.connection
      storageInitialData = { appId: 'Koding', version: '1.0' }
      account.fetchOrCreateAppStorage storageInitialData, (err, storage) ->
        console.log err  if err
        combinedStorage = storage ? {}

        fin()

    (fin) ->
      bongoModels.JMachine.some$ client, {}, (err, machines) ->
        console.log err  if err
        userMachines = machines or []
        fin()

    (fin) ->
      bongoModels.JComputeStack.some$ client, {}, (err, stacks) ->
        console.log err  if err
        userStacks = stacks or []
        fin()

    (fin) ->
      client.connection.delegate.fetchUser (err, user) ->
        if err
          console.error '[scriptblock] user not found', err
          return fin()

        if user
          userId     = user.getId()
          userEmail  = user.getAt 'email'
          userStatus = user.getAt 'status'
        else
          console.error '[scriptblock] user not found', err

        fin()

  ]

  async.parallel queue, ->
    # datafixes is noop if no op is required. (pun intended)
    require('./datafixes') client, currentGroup, (err, data) ->
      callback null, createHTML()
