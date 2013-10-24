{
  renderOauthPopup
  saveOauthToSession
}             = require './helpers'
koding        = require './bongo'
#{key, secret} = KONFIG.twitter
provider      = "twitter"

{
  renderOauthPopup
  saveOauthToSession
}                  = require './helpers'
#{twitter}          = KONFIG
http               = require "https"
koding             = require './bongo'
provider           = "twitter"

module.exports = (req, res) ->
  {oauth_token, oauth_verifier} = req.query
  {clientId}                    = req.cookies
  {JSession, JUser}             = koding.models

  JSession.one {clientId}, (err, session)=>
    if err
      renderOauthPopup res, {error:err, provider}
      return

    {username}           = session.data
    {requestTokenSecret} = session.foreignAuth.twitter

    # TODO: get from config
    key    = "aFVoHwffzThRszhMo2IQQ"
    secret = "QsTgIITMwo2yBJtpcp9sUETSHqEZ2Fh7qEQtRtOi2E"

    {OAuth}       = require "oauth"
    #config        = KONFIG.twitter
    #{key, secret} = config

    oauth   = new OAuth "https://twitter.com/oauth/request_token",
      "https://twitter.com/oauth/access_token", key, secret,
      "1.0", "http://127.0.0.1:3020/-/oauth/twitter/callback", "HMAC-SHA1"

    oauth.getOAuthAccessToken oauth_token, requestTokenSecret, oauth_verifier,
      (err, oauthAccessToken, oauthAccessTokenSecret, results)->
        if err
          renderOauthPopup res, {error:err, provider}
          return

        oauth.get 'https://api.twitter.com/1.1/account/verify_credentials.json',
          oauthAccessToken, oauthAccessTokenSecret, (error, data)->
            if err
              renderOauthPopup res, {error:err, provider}
              return

            try
              response = JSON.parse data
            catch e
              renderOauthPopup res, {error:"twitter err: parsing json", provider}
              return

            twitter                   = session.foreignAuth.twitter
            twitter.token             = oauthAccessToken
            twitter.accessTokenSecret = oauthAccessTokenSecret
            twitter.foreignId         = response.id
            twitter.profile           = response

            saveOauthToSession twitter, clientId, provider, (err)->
              if err
                renderOauthPopup res, {error:err, provider}
                return

              renderOauthPopup res, {error:null, provider}
