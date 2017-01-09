globals           = require 'globals'
kd                = require 'kd'
kookies           = require 'kookies'
Bongo             = require '@koding/bongo-client'
async             = require 'async'
remote_extensions = require './remote-extensions'

getSessionToken = -> kookies.get 'clientId'

createInstance = ->

  bongoInstance = new Bongo
    debug: no
    apiEndpoint    : globals.config.socialApiUri
    apiDescriptor  : globals.REMOTE_API
    resourceName   : globals.config.resourceName ? 'koding-social'
    getSessionToken: getSessionToken

    getUserArea    : ->

      { groupsController } = kd.singletons
      groupsController?.getUserArea()

    fetchName      : do ->
      cache = {}
      (nameStr, callback) ->
        if cache[nameStr]?
          return callback null, cache[nameStr], name
        @api.JName.one { name: nameStr }, (err, name) =>
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
          queue = name.slugs.map (slug) => (fin) =>
            selector = {}
            selector[slug.usedAsPath] = slug.slug
            @api[slug.constructorName].one? selector, (err, model) ->
              if err then callback err
              else
                unless model?
                  err = new Error \
                    "Unable to find model: #{nameStr} of type #{name.constructorName}"
                else
                  models.push model
                fin()

          async.parallel queue, =>
            @emit 'modelsReady'
            cache[nameStr] = models
            callback err, models, name
    mq: null

  bongoInstance.once 'ready', ->
    globals.combinedStorage = bongoInstance.revive globals.combinedStorage
    remote_extensions.initialize bongoInstance

  return bongoInstance


module.exports = createInstance()
