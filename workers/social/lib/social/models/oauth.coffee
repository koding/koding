bongo    = require 'bongo'
{secure, signature} = bongo
crypto   = require 'crypto'
oauth    = require "oauth"

module.exports = class OAuth extends bongo.Base
  @share()

  @set
    sharedMethods   :
      static        :
        getUrl      : (signature String, Function)

  @getUrl = secure (client, provider, callback)->
    switch provider
      when "github"
        {clientId} = KONFIG.github
        url = "https://github.com/login/oauth/authorize?client_id=#{clientId}&scope=user:email"
        callback null, url
      when "facebook"
        {clientId, redirectUri} = KONFIG.facebook
        url = "https://facebook.com/dialog/oauth?client_id=#{clientId}&redirect_uri=#{redirectUri}"
        callback null, url
      when "google"
        {client_id, redirect_uri} = KONFIG.google

        url  = "https://accounts.google.com/o/oauth2/auth?"
        url += "scope=https://www.google.com/m8/feeds "
        url += "https://www.googleapis.com/auth/userinfo.profile "
        url += "https://www.googleapis.com/auth/userinfo.email&"
        url += "redirect_uri=#{redirect_uri}&"
        url += "response_type=code&"
        url += "client_id=#{client_id}&"
        url += "access_type=offline"

        callback null, url
      when "linkedin"
        {client_id, redirect_uri} = KONFIG.linkedin
        state = crypto.createHash("md5").update((new Date).toString()).digest("hex")

        url  = "https://www.linkedin.com/uas/oauth2/authorization?"
        url += "response_type=code&"
        url += "client_id=#{client_id}&"
        url += "state=#{state}&"
        url += "redirect_uri=#{redirect_uri}"

        callback null, url
      when "odesk"
        @saveTokensAndReturnUrl client, "odesk", callback
      when "twitter"
        @saveTokensAndReturnUrl client, "twitter", callback

  @saveTokensAndReturnUrl = (client, provider, callback)->
    @getTokens provider, (err, {requestToken, requestTokenSecret, url})=>
      return callback err  if err

      credentials = {requestToken, requestTokenSecret}
      @saveTokens client, provider, credentials, (err)->
        callback err, url

  @getTokens = (provider, callback)->
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

    client.getOAuthRequestToken (err, token, tokenSecret, results)->
      return callback err  if err

      tokenizedUrl = secret_url+token
      callback null, {
        requestToken       : token
        requestTokenSecret : tokenSecret
        url                : tokenizedUrl
      }

  @saveTokens = (client, provider, credentials, callback)->
    JSession = require './session'
    JSession.one {clientId: client.sessionToken}, (err, session) ->
      return callback err  if err

      query = {}
      query["foreignAuth.#{provider}"] = credentials
      session.update $set: query, callback
