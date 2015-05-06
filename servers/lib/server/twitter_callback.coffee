# Twitter doesn't allow localhost as a callback url, so it's
# set to 127.0.0.1 instead. If testing twitter, you'll need to
# start koding in 127.0.0.1, which can be configured in config.

provider             = "twitter"
http                 = require "https"
koding               = require './bongo'
{OAuth}              = require "oauth"

{
  redirectOauth
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
      redirectOauth res, provider, err
      return

    {username}           = session.data
    {foreignAuth}        = session
    {requestTokenSecret} = foreignAuth[provider]

    client = new OAuth request_url, access_url, key, secret, version,
      redirect_uri, signature

    client.getOAuthAccessToken oauth_token, requestTokenSecret, oauth_verifier,
      (err, oauthAccessToken, oauthAccessTokenSecret, results)->
        if err
          redirectOauth res, provider, err
          return

        client.get 'https://api.twitter.com/1.1/account/verify_credentials.json',
          oauthAccessToken, oauthAccessTokenSecret, (error, data)->
            if err
              redirectOauth res, provider, err
              return

            try
              response = JSON.parse data
            catch e
              redirectOauth res, provider, "twitter: parsing json"
              return

            [firstName, restOfNames...] = response.name.split ' '
            lastName = restOfNames.join ' '

            twitter                   = foreignAuth[provider]
            twitter.token             = oauthAccessToken
            twitter.accessTokenSecret = oauthAccessTokenSecret
            twitter.foreignId         = response.id
            twitter.firstName         = firstName
            twitter.lastName          = lastName
            twitter.profile           = response

            saveOauthToSession twitter, clientId, provider, (err)->
              if err
                redirectOauth res, provider, err
                return

              redirectOauth res, provider, null
