module.exports = (KONFIG, credentials, options) ->
  #-------- runtimeOptions: PROPERTIES SHARED WITH BROWSER --------#
  KONFIG.client.runtimeOptions =
    environment          : options.environment                        # this is where browser knows what kite environment to query for
    version              : options.version
    userSitesDomain      : options.userSitesDomain
    disabledFeatures     : options.disabledFeatures
    domains              : options.domains
    resourceName         : options.socialQueueName
    sendEventsToSegment  : options.sendEventsToSegment
    suppressLogs         : options.suppressLogs
    sessionCookie        : KONFIG.sessionCookie
    collaboration        : KONFIG.collaboration
    socialApiUri         : '/xhr'
    apiUri               : '/'
    mainUri              : '/'
    userProxyHost        : options.userProxyHost
    userProxyUri         : options.userProxyUri
    userTunnelUri        : options.userTunnelUri
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
    google               : { apiKey: credentials.google.apiKey }
    gitlab               : { team: credentials.gitlab.team }
    embedly              : { apiKey: credentials.embedly.apiKey }
    github               : { clientId: credentials.github.clientId }
    pubnub               : { subscribekey: credentials.pubnub.subscribekey, ssl: credentials.pubnub.ssl,  enabled: credentials.pubnub.enabled }
    newkontrol           : { url: KONFIG.kontrol.url }
    recaptcha            : { enabled : KONFIG.recaptcha.enabled, key : credentials.recaptcha.public, invisible_key: credentials.recaptcha.invisible_public }
    uploadsUri           : 'https://koding-uploads.s3.amazonaws.com'
    uploadsUriForGroup   : 'https://koding-groups.s3.amazonaws.com'
    intercomAppId        : credentials.intercomAppId
