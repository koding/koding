provider             = "odesk"
http                 = require "https"
koding               = require './bongo'
{parseString}        = require "xml2js"
{OAuth}              = require "oauth"

{
  renderOauthPopup
  saveOauthToSession
}                    = require './helpers'

{
  key
  secret
  request_url
  access_url
  version
  redirect_uri
  signature
}                    = KONFIG[provider]

module.exports = (req, res)->
  {query, cookies} = req
  {oauth_token, oauth_verifier} = query
  {clientId} = cookies

  {JSession} = koding.models

  JSession.one {clientId}, (err, session)->
    if err or not session
      renderOauthPopup res, {error:err, provider}
      return

    {foreignAuth}        = session
    {username}           = session.data
    {requestTokenSecret} = foreignAuth[provider]

    customHeaders =
      'Accept'     : 'application/json',
      'Connection' : 'close',
      'User-Agent' : 'Koding'

    client = new OAuth request_url, access_url, key, secret, version, redirect_uri,
      signature, 0 , customHeaders

    client.getOAuthAccessToken oauth_token, requestTokenSecret, oauth_verifier,\
      (err, accessToken, accessTokenSecret) ->
        if err
          renderOauthPopup res, {error:err, provider}
          return

        client.get 'https://www.odesk.com/api/auth/v1/info',
          accessToken, accessTokenSecret, (err, data)->
            try
              response = JSON.parse data
            catch e
              renderOauthPopup res, {error:"Error parsing user info", provider}

            odesk                   = session.foreignAuth.odesk
            odesk.token             = accessToken
            odesk.accessTokenSecret = accessTokenSecret
            odesk.foreignId         = response.auth_user.uid
            odesk.profileUrl        = response.info.profile_url
            odesk.profile           = response

            saveOauthToSession odesk, clientId, provider, (err)->
              if err
                renderOauthPopup res, {error:err, provider}
                return

              renderOauthPopup res, {error:null, provider}
