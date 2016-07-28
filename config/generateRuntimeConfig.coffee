module.exports = (KONFIG, credentials, options) ->
  #-------- runtimeOptions: PROPERTIES SHARED WITH BROWSER --------#
  # NOTE: when you add to runtime options below, be sure to modify
  # `RuntimeOptions` struct in `go/src/koding/tools/config/config.go`
  KONFIG.client.runtimeOptions =
    environment          : options.environment                        # this is where browser knows what kite environment to query for
    version              : options.version
    userSitesDomain      : options.userSitesDomain
    disabledFeatures     : options.disabledFeatures
    domains              : options.domains
    resourceName         : options.socialQueueName
    sendEventsToSegment  : options.sendEventsToSegment
    suppressLogs         : options.suppressLogs
    paymentBlockDuration : options.paymentBlockDuration
    siftScience          : credentials.siftSciencePublic
    sessionCookie        : KONFIG.sessionCookie
    collaboration        : KONFIG.collaboration
    authExchange         : 'auth'
    socialApiUri         : '/xhr'
    apiUri               : '/'
    sourceMapsUri        : '/sourcemaps'
    mainUri              : '/'
    fileFetchTimeout     : 1000 * 15
    userIdleMs           : 1000 * 60 * 5
    kites                : require './kites.coffee'           # browser passes this version information to kontrol , so it connects to correct version of the kite.
    externalProfiles     :
      google             : { nicename: 'Google' }
      linkedin           : { nicename: 'LinkedIn' }
      twitter            : { nicename: 'Twitter' }
      facebook           : { nicename: 'Facebook', urlLocation: 'link' }
      github             : { nicename: 'GitHub', urlLocation: 'html_url' }
      gitlab             : { nicename: 'GitLab' }
    entryPoint           : { slug:'koding', type:'group' }
    troubleshoot         : { idleTime: 1000 * 60 * 60, externalUrl: 'https://s3.amazonaws.com/koding-ping/healthcheck.json' }
    stripe               : { token: credentials.stripe.publicToken }
    broker               : { uri: '/subscribe' }
    google               : { apiKey: '' }
    gitlab               : { team: credentials.gitlab?.team ? null }
    paypal               : { formUrl: credentials.paypal.formUrl }
    embedly              : { apiKey: credentials.embedly.apiKey }
    algolia              : { appId: credentials.algolia.appId, indexSuffix: options.algoliaIndexSuffix }
    github               : { clientId: credentials.github.clientId }
    pubnub               : { subscribekey: credentials.pubnub.subscribekey, ssl: credentials.pubnub.ssl,  enabled: credentials.pubnub.enabled }
    integration          : { url: KONFIG.integration.url }
    webhookMiddleware    : { url: KONFIG.socialapi.webhookMiddleware.url }
    newkontrol           : { url: KONFIG.kontrol.url }
    recaptcha            : { enabled : KONFIG.recaptcha.enabled, key : credentials.recaptcha.public }
    contentRotatorUrl    : 'http://koding.github.io'
    uploadsUri           : 'https://koding-uploads.s3.amazonaws.com'
    uploadsUriForGroup   : 'https://koding-groups.s3.amazonaws.com'
    intercomAppId        : credentials.intercomAppId
