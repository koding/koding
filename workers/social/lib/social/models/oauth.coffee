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

  @PROVIDERS =

    # -- GITLAB PROVIDER --------------------------------------------------8<--

    gitlab    :
      title   : 'GitLab OAuth Provider'
      enabled : true
      getUrl  : (client, urlOptions, callback) ->

        checkGroupGitLabSettings = (client, callback) ->

          { sessionToken: clientId, context: { group: slug } } = client

          JSession = require './session'
          JSession.one { clientId }, (err, session) ->
            return callback err  if err
            return callback new KodingError 'Session invalid'  unless session

            JGroup = require './group'
            JGroup.one { slug }, (err, group) ->

              if not err and group and group.config?.gitlab?.enabled

                settings = {
                  url: group.config.gitlab.url
                  applicationId: group.config.gitlab.applicationId
                  state: session._id
                }

                callback null, settings

              else

                callback new KodingError 'Integration is not enabled'

        { returnUrl, redirectUri } = urlOptions
        { applicationId, host, port } = KONFIG.gitlab
        protocol = '//'
        port = if port then ":#{port}" else ''
        host = urlOptions.host ? host
        redirectUri = "#{redirectUri}?returnUrl=#{returnUrl}"  if returnUrl

        checkGroupGitLabSettings client, (err, data) ->
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
      title   : 'Github OAuth Provider'
      enabled : false
      getUrl  : (client, urlOptions, callback) ->

        { clientId } = KONFIG.github
        { scope, returnUrl } = urlOptions
        scope = 'user:email'  unless scope
        redirectUri = "#{redirectUri}?returnUrl=#{returnUrl}"  if returnUrl

        url  = 'https://github.com/login/oauth/authorize?'
        url += "client_id=#{clientId}&"
        url += "scope=#{scope}&redirect_uri=#{redirectUri}"

        callback null, url

      validateOAuth: (options, callback) ->
        callback ERROR.VALIDATION


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
        "http://#{group}.#{KONFIG.hostname}/-/oauth/#{provider}/callback"
      _provider.getUrl client, urlOptions, callback
    else
      callback ERROR.NOTSUPPORTED


  @validateOAuth = (provider, options, callback) ->

    if (_provider = @PROVIDERS[provider]) and _provider.enabled
      _provider.validateOAuth options, callback
    else
      callback ERROR.NOTSUPPORTED
