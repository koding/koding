bongo       = require 'bongo'
{ secure, signature } = bongo
crypto      = require 'crypto'
oauth       = require 'oauth'
parser      = require 'url'
KodingError = require '../error'
JSession    = require './session'

module.exports = class OAuth extends bongo.Base

  @share()

  @set
    sharedMethods   :
      static        :
        getUrl      : (signature Object, Function)


  getUrlFor = (provider, redirectUri, options, callback) ->

    {

      github: ->

        { clientId } = KONFIG.github
        { scope, returnUrl } = options
        scope = 'user:email'  unless scope
        redirectUri = "#{redirectUri}?returnUrl=#{returnUrl}"  if returnUrl
        url = "https://github.com/login/oauth/authorize?client_id=#{clientId}&scope=#{scope}&redirect_uri=#{redirectUri}"

        callback null, url


      gitlab: ->

        { applicationId, host, redirectUri, port } = KONFIG.gitlab
        { returnUrl } = options
        host ?= 'gitlab.com'
        protocol = '//'
        port = if port then ":#{port}" else ''
        host = options.host ? host
        redirectUri = "#{redirectUri}?returnUrl=#{returnUrl}"  if returnUrl
        url = "#{protocol}#{host}#{port}/oauth/authorize?client_id=#{applicationId}&redirect_uri=#{redirectUri}&response_type=code"

        callback null, url


      facebook: ->

        { clientId } = KONFIG.facebook
        url = "https://facebook.com/dialog/oauth?client_id=#{clientId}&redirect_uri=#{redirectUri}&scope=email"

        callback null, url


      google: ->

        { client_id } = KONFIG.google
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


      linkedin: ->

        { client_id } = KONFIG.linkedin
        state = crypto.createHash('md5').update((new Date).toString()).digest('hex')

        url  = 'https://www.linkedin.com/uas/oauth2/authorization?'
        url += 'response_type=code&'
        url += "client_id=#{client_id}&"
        url += "state=#{state}&"
        url += "redirect_uri=#{redirectUri}"

        callback null, url


    }[provider]?()


  @getUrl = secure (client, options, callback) ->

    { provider } = options

    if redirectUri = KONFIG[provider].redirectUri or KONFIG[provider].redirect_uri
      redirectUri  = @prependGroupName redirectUri, client.context.group

    if provider is 'twitter'
      @saveTokensAndReturnUrl client, 'twitter', callback
    else
      getUrlFor provider, redirectUri, options, callback


  @prependGroupName = (url, groupName) ->
    return url  if groupName is 'koding'

    url = parser.parse url

    return "#{url.protocol}//#{groupName}.#{url.host}#{url.path}"


  @saveTokensAndReturnUrl = (client, provider, callback) ->
    @getTokens provider, (err, data) =>
      return callback err  if err
      { requestToken, requestTokenSecret, url } = data

      credentials = { requestToken, requestTokenSecret }
      @saveTokens client, provider, credentials, (err) ->
        callback err, url


  @getTokens = (provider, callback) ->
    {
      key
      secret
      request_url
      access_url
      version
      redirect_uri
      signature
      secret_url
    }      = KONFIG[provider]

    client = new oauth.OAuth request_url, access_url, key, secret, version,
      redirect_uri, signature

    client.getOAuthRequestToken (err, token, tokenSecret, results) ->
      return callback err  if err

      tokenizedUrl = secret_url + token
      callback null, {
        requestToken       : token
        requestTokenSecret : tokenSecret
        url                : tokenizedUrl
      }


  @saveTokens = (client, provider, credentials, callback) ->
    JSession.one { clientId: client.sessionToken }, (err, session) ->
      return callback err  if err
      return callback new KodingError 'Session not found'  unless session

      query = {}
      query["foreignAuth.#{provider}"] = credentials
      session.update { $set: query }, callback
