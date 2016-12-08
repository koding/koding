bongo       = require 'bongo'
{ secure, signature } = bongo
crypto      = require 'crypto'
request     = require 'request'
KodingError = require '../error'

{ isAddressValid, cleanUrl } = require './utils'


module.exports = class OAuth extends bongo.Base

  @share()

  @set
    sharedMethods   :
      static        :
        getUrl      : (signature Object, Function)

  ERRORS =
    NOTSUPPORTED : new KodingError 'OAuth provider is not supported'
    VALIDATION   : new KodingError 'OAuth validation failed'

  # -- OAUTH PROVIDERS ----------------------------------------------------8<--

  checkGroupIntegrationSettings = (provider, client, callback) ->

    { sessionToken: clientId, context: { group: slug } } = client

    JSession = require './session'
    JSession.one { clientId }, (err, session) ->
      return callback err  if err
      return callback new KodingError 'Session invalid'  unless session

      JGroup = require './group'
      JGroup.one { slug }, (err, group) ->

        if not err and group and group.config?[provider]?.enabled

          settings = {
            url: group.config[provider].url
            scope: group.config[provider].scope
            applicationId: group.config[provider].applicationId
            state: session._id
          }

          callback null, settings

        else

          callback new KodingError 'Integration is not enabled'


  @PROVIDERS = PROVIDERS =

    # -- GITLAB PROVIDER --------------------------------------------------8<--

    gitlab    :
      title   : 'GitLab OAuth Provider'
      enabled : true
      getUrl  : (client, urlOptions, callback) ->

        { returnUrl, redirectUri } = urlOptions
        { applicationId, host, port } = KONFIG.gitlab
        protocol = '//'
        port = if port then ":#{port}" else ''
        host = urlOptions.host ? host
        redirectUri = "#{redirectUri}?returnUrl=#{returnUrl}"  if returnUrl

        checkGroupIntegrationSettings 'gitlab', client, (err, data) ->
          return callback err  if err

          url = "#{protocol}#{host}#{port}"
          { url, applicationId, state } = data  if data

          state = "&state=#{state}"
          url   = "#{url}/oauth/authorize?"
          url  += "client_id=#{applicationId}&"
          url  += "response_type=code#{state}&"
          url  += "redirect_uri=#{redirectUri}"

          callback null, url

      validateOAuth: (options, callback) ->

        { url, applicationId, applicationSecret } = options

        MissingFieldError = 'Missing field for validating oauth'

        if not url then return callback new KodingError \
          MissingFieldError, 'MissingField', { fields: ['url'] }
        if not applicationId then return callback new KodingError \
          MissingFieldError, 'MissingField', { fields: ['applicationId'] }
        if not applicationSecret then return callback new KodingError \
          MissingFieldError, 'MissingField', { fields: ['applicationSecret'] }

        url = cleanUrl url

        isAddressValid url, (err) ->

          if err
            err.error = { fields: ['url'] }
            return callback err

          options           =
            url             : "#{url}/oauth/token"
            timeout         : 7000
            method          : 'POST'
            headers         :
              'Accept'      : 'application/json'
              'User-Agent'  : 'Koding'
            json            :
              grant_type    : 'client_credentials'
              client_id     : applicationId
              client_secret : applicationSecret

          request options, (error, response, body) ->

            if error
              callback new KodingError \
                'Host not reachable', 'NotReachable', { fields: ['url'] }
            else if not body.access_token
              callback new KodingError \
                'Verification failed', 'VerificationFailed', { fields: [
                    'applicationSecret',
                    'applicationId'
                ] }
            else
              callback null, { url }


    # -- GITHUB PROVIDER --------------------------------------------------8<--

    github    :
      title   : 'GitHub OAuth Provider'
      enabled : yes
      scopes  : ['user', 'user:email', 'user:follow', 'public_repo', 'repo',
                 'repo_deployment', 'repo:status', 'delete_repo',
                 'notifications', 'gist', 'read:repo_hook', 'write:repo_hook',
                 'admin:repo_hook', 'admin:org_hook', 'read:org', 'write:org',
                 'admin:org', 'read:public_key', 'write:public_key',
                 'admin:public_key', 'read:gpg_key', 'write:gpg_key',
                 'admin:gpg_key']
      getUrl  : (client, urlOptions, callback) ->

        { scope, returnUrl, redirectUri } = urlOptions
        redirectUri = "#{redirectUri}?returnUrl=#{returnUrl}"  if returnUrl

        checkGroupIntegrationSettings 'github', client, (err, data) ->
          return callback err  if err

          url = 'https://github.com'

          { applicationId, state } = data ? {}
          scope ?= data.scope

          state = "&state=#{state}"
          url   = "#{url}/login/oauth/authorize?"
          url  += "client_id=#{applicationId}&"
          url  += "scope=#{scope}#{state}&"
          url  += "redirect_uri=#{redirectUri}"

          callback null, url

      validateOAuth: (options, callback) ->

        { applicationId, applicationSecret, scope } = options

        MissingFieldError = 'Missing field for validating oauth'

        if not applicationId then return callback new KodingError \
          MissingFieldError, 'MissingField', { fields: ['applicationId'] }
        if not applicationSecret then return callback new KodingError \
          MissingFieldError, 'MissingField', { fields: ['applicationSecret'] }

        scope  = 'user:email'  if not scope or not scope.trim?()
        scopes = scope.split ', '
        scope  = (scopes
          .map    (s) -> s.trim()
          .filter (s) -> s in PROVIDERS.github.scopes
        ).join ', '

        url               = 'https://github.com'
        options           =
          url             : "#{url}/login/oauth/access_token"
          timeout         : 7000
          method          : 'POST'
          headers         :
            'Accept'      : 'application/json'
            'User-Agent'  : 'Koding'
          json            :
            client_id     : applicationId
            client_secret : applicationSecret

        request options, (error, response, body) ->

          if error
            callback new KodingError \
              'Host not reachable', 'NotReachable', { fields: [] }
          else
            # Github OAuth does not support [grant_type = 'client_credentials']
            # so, to make sure if client_id and client_secret are valid we are
            # requesting a new token without a code here, if it passes and
            # fails with bad_verification_code means provided auths are ok ~GG
            if body.error is 'bad_verification_code'
              callback null, { url, scope }
            else
              callback new KodingError \
                'Verification failed', 'VerificationFailed', { fields: [
                    'applicationSecret',
                    'applicationId'
                ] }


    # -- FACEBOOK PROVIDER ------------------------------------------------8<--

    facebook  :
      title   : 'Facebook OAuth Provider'
      enabled : false
      getUrl  : (client, urlOptions, callback) ->

        { clientId } = KONFIG.facebook
        { redirectUri } = urlOptions

        url  = 'https://facebook.com/dialog/oauth?'
        url += "client_id=#{clientId}&"
        url += "redirect_uri=#{redirectUri}&scope=email"

        callback null, url

      validateOAuth: (options, callback) ->
        callback ERROR.VALIDATION


    # -- GOOGLE PROVIDER --------------------------------------------------8<--

    google    :
      title   : 'Google OAuth Provider'
      enabled : false
      getUrl  : (client, urlOptions, callback) ->

        { client_id } = KONFIG.google
        { redirectUri } = urlOptions

        JSession = require './session'
        JSession.one { clientId: client.sessionToken }, (err, session) ->
          return callback err  if err

          state = session._id
          url  = 'https://accounts.google.com/o/oauth2/auth?'
          url += 'scope=https://www.google.com/m8/feeds '
          url += 'https://www.googleapis.com/auth/userinfo.profile '
          url += 'https://www.googleapis.com/auth/userinfo.email&'
          url += "redirect_uri=#{redirectUri}&"
          url += 'response_type=code&'
          url += "client_id=#{client_id}&"
          url += "state=#{state}&"
          url += 'access_type=offline'

          callback null, url

      validateOAuth: (options, callback) ->
        callback ERROR.VALIDATION


    # -- LINKEDIN PROVIDER ------------------------------------------------8<--

    linkedin  :
      title   : 'LinkedIn OAuth Provider'
      enabled : false
      getUrl  : (client, urlOptions, callback) ->

        { client_id } = KONFIG.linkedin
        { redirectUri } = urlOptions

        state = crypto.createHash('md5')
          .update((new Date).toString())
          .digest('hex')

        url  = 'https://www.linkedin.com/uas/oauth2/authorization?'
        url += 'response_type=code&'
        url += "client_id=#{client_id}&"
        url += "state=#{state}&"
        url += "redirect_uri=#{redirectUri}"

        callback null, url

      validateOAuth: (options, callback) ->
        callback ERROR.VALIDATION


  # -- END OF PROVIDERS ---------------------------------------------------8<--


  @getUrl = secure (client, urlOptions, callback) ->

    { provider } = urlOptions

    if (_provider = @PROVIDERS[provider]) and _provider.enabled
      { context: { group } } = client
      urlOptions.redirectUri = \
        "#{KONFIG.protocol}//#{group}.#{KONFIG.hostname}/-/oauth/#{provider}/callback"
      _provider.getUrl client, urlOptions, callback
    else
      callback ERROR.NOTSUPPORTED


  @validateOAuth = (provider, options, callback) ->

    if (_provider = @PROVIDERS[provider]) and _provider.enabled
      _provider.validateOAuth options, callback
    else
      callback ERROR.NOTSUPPORTED
