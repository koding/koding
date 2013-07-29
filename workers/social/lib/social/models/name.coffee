{Model, Base} = require 'bongo'

module.exports = class JName extends Model

  KodingError = require '../error'

  {secure, JsPath:{getAt}, dash} = require 'bongo'

  createId = require 'hat'

  @share()

  @set
    softDelete        : yes
    sharedMethods     :
      static          : ['one','claimNames','migrateAllOldNames']
      instance        : ['migrateOldName']
    indexes           :
      name            : ['unique']
    schema            :
      name            : String
      slugs           : Array # [collectionName, constructorName, slug, usedAsPath]
      constructorName : String
      usedAsPath      : String

  @cycleSecretName =(name, callback)->
    JSecretName = require './secretname'
    JSecretName.one {name}, (err, secretNameObj)=>
      if err then callback err
      else unless secretNameObj?
        callback new KodingError "Unknown name #{name}"
      else
        oldSecretName = secretNameObj.secretName
        secretName    = createId()
        secretNameObj.update {
          $set: { oldSecretName, secretName }
        }, -> callback null, oldSecretName, secretName
        setTimeout ->
          secretNameObj.update { $unset: oldSecretName: 1 }, ->
        , 5000

  @fetchSecretName =(name, callback)->
    JSecretName = require './secretname'
    JSecretName.one {name}, (err, secretNameObj) =>
      if err then callback err
      else unless secretNameObj
        secretNameObj = new JSecretName {name}
        secretNameObj.save (err) =>
          if err then callback err
          else callback null, secretNameObj.secretName
      else
        # TODO: we could possibly try to create the conversation slice by
        #  observing an event that we could emit from here.
        #@emit 'channel-control'
        callback null, secretNameObj.secretName, secretNameObj.oldSecretName

  slowEach_ =(cursor, callback=->)->
    cursor.nextModel (err, name)->
      if err then callback err
      else unless name? then callback null
      else
        console.log 'migrating', name
        name.migrateOldName (err)->
          callback err  if err?
          console.log 'done'
          slowEach_ cursor

  @migrateAllOldNames = secure (client, callback)->
    @cursor { constructorName: $exists: yes }, {}, (err, cursor)->
      if err then callback err
      else slowEach_ cursor, console.error

  stripTemplate =(konstructor, nameStr)->
    {slugTemplate} = konstructor#Base.constructors[@constructorName]
    return nameStr  unless slugTemplate
    slugStripPattern = /^(.+)?(#\{slug\})(.+)?$/
    re = RegExp slugTemplate.replace slugStripPattern,
      (tmp, begin, slug, end)-> "^#{begin ? ''}(.*)#{end ? ''}$"
    nameStr.match(re)?[1]

  stripTemplate:->
    stripTemplate Base.constructors[@constructorName], @name

  migrateOldName:(callback=->)->
    return  unless @constructorName?
    slug = @stripTemplate()
    selector = {}
    selector[@usedAsPath] = slug
    konstructor = Base.constructors[@constructorName]
    konstructor.one selector, (err, model)=>
      if err then callback err
      else unless model?
        @remove callback
      else
        {collectionName} = model.getCollection()
        newName = {
          slug, collectionName, @usedAsPath, @constructorName
        }
        kallback = do -> i = 0; (err)->
          if err then callback err
          else if ++i is 2 then callback null
        @update {$set: slugs: [newName]}, kallback
        @update {$unset: {constructorName:1, usedAsPath:1}}, kallback

  @fetchModels =do->
    fetchByNameObject =(nameObj, callback)->
      models = []
      queue = nameObj.slugs.map (slug, i)->->
        konstructor = Base.constructors[slug.constructorName]
        selector = {}
        selector[slug.usedAsPath] = slug.slug
        konstructor.one selector, (err, model)->
          models[i] = model
          queue.fin()
      dash queue, -> callback null, models, nameObj

    fetchModels = (name, callback)->
      if 'string' is typeof name
        @one {name}, (err, nameObj)->
          if err then next err
          else unless nameObj? then callback null
          else fetchByNameObject nameObj, callback
      else
        fetchByNameObject name, callback

  fetchModels:(callback)-> @fetchModels this, callback

  @release =(name, callback=->)->
    @remove {name}, callback

  @validateName =(candidate)->
    3 < candidate.length < 26 and /^[a-z0-9][a-z0-9-]+$/.test candidate

  @claimNames = secure (client, callback=->)->
    unless client.connection.delegate.can 'administer names'
      callback new KodingError 'Access denied'
    else
      @claimAll [
        { konstructor: require('./user'),  usedAsPath: 'username' }
        { konstructor: require('./group'), usedAsPath: 'slug' }
      ], callback

  @claim =(fullName, slugs, konstructor, usedAsPath, callback)->
    [callback, usedAsPath] = [usedAsPath, callback]  unless callback
    nameDoc = new this {
      name: fullName
      slugs
    }
    nameDoc.save (err)->
      if err?.code is 11000
        err = new KodingError "The slug #{fullName} is not available."
        err.code = 11000
        callback err
      else if err
        callback err
      else
        callback null, fullName

  @claimAll = (sources, callback=->)->
    i = 0
    konstructorCount = sources.length
    sources.forEach ({konstructor, usedAsPath})=>
      fields = {}
      fields[usedAsPath] = 1
      j = 0
      konstructor.count (err, docCount)=>
        if err then callback err
        else
          konstructor.someData {}, fields, (err, cursor)=>
            if err then callback err
            else
              cursor.each (err, doc)=>
                if err then callback err
                else if doc?
                  {collectionName} = konstructor.getCollection()
                  name = getAt doc, usedAsPath
                  slug = {
                    collectionName
                    usedAsPath
                    constructorName   : konstructor.name
                    slug              : stripTemplate konstructor, name
                  }
                  @claim name, [slug], konstructor, (err)->
                    if err
                      console.log "Couln't claim name #{name}"
                      callback err
                    else if ++j is docCount and ++i is konstructorCount
                      callback null