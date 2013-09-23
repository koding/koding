koding             = require './bongo'
{renderOauthPopup} = require './helpers'

module.exports = (req, res) ->
  {oauth_token, oauth_verifier} = req.query
  {clientId}                  = req.cookies
  {JSession, JUser}           = koding.models

  JSession.one {clientId}, (err, session)=>
    if err
      console.log "odesk err: fetch session", err
      renderOauthPopup res, {error:err, provider:"odesk"}
      return

    {username} = session.data
    JUser.one {username}, (err, user) =>
      if err
        console.log "odesk err: fetching user", err
        renderOauthPopup res, {error:err, provider:"odesk"}
        return

      {requestTokenSecret} = user.foreignAuth.odesk
      Odesk                = require 'node-odesk'
      {key, secret}        = KONFIG.odesk

      o = new Odesk key, secret
      o.OAuth.getAccessToken oauth_token, requestTokenSecret, oauth_verifier,\
        (err, accessToken, accessTokenSecret) ->
          if err
            console.log "odesk err: getting tokens", err
            renderOauthPopup res, {error:err, provider:"odesk"}
            return

          o.OAuth.accessToken       = accessToken
          o.OAuth.accessTokenSecret = accessTokenSecret

          o.get 'auth/v1/info', (err, data)->
            if err
              console.log "odesk err, fetching user info", err, data
              renderOauthPopup res, {error:err, provider:"odesk"}
              return

            odesk                   = user.foreignAuth.odesk
            odesk.accessToken       = accessToken
            odesk.accessTokenSecret = accessTokenSecret
            odesk.foreignId         = data.auth_user.uid

            session.update $set: {"foreignAuth.odesk": odesk}, ->
              renderOauthPopup res, {error:null, provider:"odesk"}
