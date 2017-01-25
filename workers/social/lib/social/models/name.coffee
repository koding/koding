async           = require 'async'
{ Model, Base } = require 'bongo'

module.exports = class JName extends Model

  KodingError = require '../error'

  { secure, JsPath:{ getAt }, signature } = require 'bongo'

  @share()

  @set
    softDelete        : yes
    sharedMethods     :
      static          :
        one:
          (signature Object, Function)
        claimNames:
          (signature Function)

    sharedEvents      :
      instance        : []
      static          : []
    indexes           :
      name            : ['unique']
    schema            :
      name            : String
      slugs           : [ Object ] # [collectionName, constructorName, slug, usedAsPath]
      constructorName : String
      usedAsPath      : String
    registeredAt      :
      type            : Date
      default         : -> new Date

  stripTemplate = (konstructor, nameStr) ->
    { slugTemplate } = konstructor#Base.constructors[@constructorName]
    return nameStr  unless slugTemplate
    slugStripPattern = /^(.+)?(#\{slug\})(.+)?$/
    re = RegExp slugTemplate.replace slugStripPattern,
      (tmp, begin, slug, end) -> "^#{begin ? ''}(.*)#{end ? ''}$"
    nameStr.match(re)?[1]

  stripTemplate: ->
    stripTemplate Base.constructors[@constructorName], @name

  @fetchModels = do ->

    fetchByNameObject = (nameObj, callback) ->
      models = []
      queue = nameObj.slugs.map (slug, i) -> (fin) ->
        konstructor = Base.constructors[slug.constructorName]
        return fin() unless konstructor
        selector = {}
        selector[slug.usedAsPath] = slug.slug
        konstructor.one selector, (err, model) ->
          return fin() if err or not model
          models[i] = model
          fin()

      async.parallel queue, ->
        # remove falsy values
        models = models.filter(Boolean)
        callback null, { models, name: nameObj }

    fetchModels = (name, callback) ->

      if 'string' is typeof name

        JName.one { name }, (err, nameObj) ->
          if err then callback err
          else if nameObj?
            fetchByNameObject nameObj, callback
          else
            callback null

      else if Array.isArray name

        JName.some { name: { $in: name } }, { limit: 30 }, (err, nameObjects) ->
          return callback err  if err?

          if nameObjects?
            models = []
            queue = nameObjects.map (nameObj, i) -> (fin) ->
              fetchByNameObject nameObj, (err, model) ->
                models[i] = err ? model
                fin()
            async.parallel queue, ->
              callback null, models
          else
            callback null

      else
        fetchByNameObject name, callback

  fetchModels:(callback) -> @fetchModels this, callback

  @release = (name, callback = -> ) ->
    @remove { name }, callback

  @validateName = (candidate) ->
    2 < candidate.length < 26 and /^[a-z0-9][a-z0-9-]+$/.test candidate

  @validateEmail = (candidate) ->

    isEmailValid = require './user/emailchecker'
    sanitize     = require './user/emailsanitize'
    validator    = require 'validator'
    candidate    = sanitize candidate

    return validator.isEmail(candidate) and isEmailValid candidate


  @claimNames = secure (client, callback = -> ) ->
    unless client.connection.delegate.can 'administer names'
      callback new KodingError 'Access denied'
    else
      @claimAll [
        { konstructor: require('./user'),  usedAsPath: 'username' }
        { konstructor: require('./group'), usedAsPath: 'slug' }
      ], callback

  @claim = (fullName, slugs, konstructor, usedAsPath, callback) ->
    [callback, usedAsPath] = [usedAsPath, callback]  unless callback
    nameDoc = new this {
      name: fullName
      slugs
    }
    nameDoc.save (err) ->
      if err?.code is 11000
        err = new KodingError "The slug #{fullName} is not available."
        err.code = 11000
        callback err
      else if err
        callback err
      else
        callback null, nameDoc

  @claimAll = (sources, callback = -> ) ->
    i = 0
    konstructorCount = sources.length
    sources.forEach ({ konstructor, usedAsPath }) =>
      fields = {}
      fields[usedAsPath] = 1
      j = 0
      konstructor.count (err, docCount) =>
        if err then callback err
        else
          konstructor.someData {}, fields, (err, cursor) =>
            if err then callback err
            else
              cursor.each (err, doc) =>
                if err then callback err
                else if doc?
                  { collectionName } = konstructor.getCollection()
                  name = getAt doc, usedAsPath
                  slug = {
                    collectionName
                    usedAsPath
                    constructorName   : konstructor.name
                    slug              : stripTemplate konstructor, name
                  }
                  @claim name, [slug], konstructor, (err) ->
                    if err
                      console.log "Couln't claim name #{name}"
                      callback err
                    else if ++j is docCount and ++i is konstructorCount
                      callback null
