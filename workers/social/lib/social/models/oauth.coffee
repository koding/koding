bongo    = require 'bongo'
{secure} = bongo

module.exports = class OAuth extends bongo.Base
  @share()

  @set
    sharedMethods   :
      static        : ['getUrl']

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
      when "odesk"
        @getOdeskUrl (err, url, requestToken, requestTokenSecret)=>
          if err then callback err
          else
            @saveOdeskTokens client, url, requestToken, requestTokenSecret, (err)->
              callback err, url
      when "google"
        {client_id} = KONFIG.google

        url  = "https://accounts.google.com/o/oauth2/auth?"
        url += "scope=https://www.google.com/m8/feeds/ "
        url += "https://www.googleapis.com/auth/userinfo.email "
        url += "https://www.googleapis.com/auth/userinfo.profile&"
        url += "redirect_uri=http://localhost:3020/-/oauth/google/callback&"
        url += "response_type=code&"
        url += "client_id=#{client_id}&"
        url += "access_type=offline"

        #https://accounts.google.com/o/oauth2/auth?redirect_uri=https%3A%2F%2Fdevelopers.google.com%2Foauthplayground&response_type=code&client_id=407408718192.apps.googleusercontent.com&scope=https%3A%2F%2Fwww.google.com%2Fm8%2Ffeeds%2F+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fuserinfo.email+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fuserinfo.profile&approval_prompt=force&access_type=offline

        console.log url

        callback null, url

  @getOdeskUrl = (callback)->
    Odesk         = require 'node-odesk'
    config        = KONFIG.odesk
    {key, secret} = config

    odesk = new Odesk key, secret
    odesk.OAuth.getAuthorizeUrl callback

  @saveOdeskTokens = (client, url, requestToken, requestTokenSecret, callback)->
    JSession = require './session'
    JSession.one {clientId: client.sessionToken}, (err, session) =>
      if err then callback err
      else
        odesk = {requestToken, requestTokenSecret}
        session.update $set: {"foreignAuth.odesk" : odesk}, (err)->
          callback err, url
