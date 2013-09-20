jraphical = require 'jraphical'

module.exports = class OAuth extends jraphical.Module
  {secure} = require 'bongo'

  @share()

  @set
    sharedMethods   :
      static        : ['getUrl']

  @getUrl = secure (client, provider, callback)->
    switch provider
      when "github"
        clientId = KONFIG.github
        url = "https://github.com/login/oauth/authorize?client_id=#{clientId}&scope=user:email"
        callback null, url
      when "odesk"
        @getOdeskUrl (err, url, rToken, rSecret)->
          if err then callback err
          else
            @saveOdeskTokens client, rToken, rSecret, (err)->
              calback err, url

  @getOdeskUrl = (callback)->
    Odesk         = require 'node-odesk'
    config        = KONFIG.odesk
    {key, secret} = config

    odesk = new Odesk key, secret
    odesk.OAuth.getAuthorizeUrl callback

  @saveOdeskTokens = (client, rToken, rSecret, callback)->
    JUser = require './user'
    JUser.one username:client.context.user, (err, user)->
      if err then callback err
      else
        odesk = {rToken, rSecret}
        user.update $set: {"foreignAuth.odesk" : odesk}, (err)->
          callback err, url
