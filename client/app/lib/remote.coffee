globals = require 'globals'
kd = require 'kd'
kookies = require 'kookies'
Bongo = require 'bongo-client'
broker = require 'broker-client'
sinkrow = require 'sinkrow'


getSessionToken = -> kookies.get 'clientId'

createInstance = ->

  new Bongo
    apiEndpoint    : globals.config.socialApiUri
    apiDescriptor  : globals.REMOTE_API
    resourceName   : globals.config.resourceName ? 'koding-social'
    getSessionToken: getSessionToken
    getUserArea    : -> kd.getSingleton('groupsController').getUserArea()
    fetchName      : do ->
      cache = {}
      (nameStr, callback)->
        if cache[nameStr]?
          return callback null, cache[nameStr], name
        @api.JName.one {name: nameStr}, (err, name) =>
          if err then return callback err
          else unless name?
            return callback new Error "Unknown name: #{nameStr}"
          else if name.slugs[0].constructorName is 'JUser'
            # SPECIAL CASE: map JUser over to JAccount...
            name = new @api.JName
              name              : name.name
              slugs             : [{
                constructorName : 'JAccount'
                collectionName  : 'jAccounts'
                slug            : name.name
                usedAsPath      : 'profile.nickname'
              }]
          models = []
          err = null
          queue = name.slugs.map (slug) => =>
            selector = {}
            selector[slug.usedAsPath] = slug.slug
            @api[slug.constructorName].one? selector, (err, model)->
              if err then callback err
              else
                unless model?
                  err = new Error \
                    "Unable to find model: #{nameStr} of type #{name.constructorName}"
                else
                  models.push model
                queue.fin()

          sinkrow.dash queue, =>
            @emit "modelsReady"
            cache[nameStr] = models
            callback err, models, name

    mq: do ->
      {authExchange} = globals.config

      options = {
        authExchange
        autoReconnect: yes
        getSessionToken
      }

      console.log "connecting to:" + globals.config.broker.uri

      new broker.Broker "#{globals.config.broker.uri}", options


instance = null

exports.getInstance = ->
  instance ?= createInstance()
