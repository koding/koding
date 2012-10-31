{Model} = require 'bongo'

module.exports = class JName extends Model

  KodingError = require '../error'

  @share()

  @set
    sharedMethods     :
      static          : ['claimAll']
    indexes           :
      name            : ['unique']
    schema            :
      name            : String
      constructorName : String
      usedAsPath      : String

  @claim =(name, konstructor, usedAsPath, callback)->
    constructorName = konstructor.name
    nameDoc = new @ {name, constructorName, usedAsPath}
    nameDoc.save (err)->
      if err?.code is 11000
        callback new KodingError "The name #{name} is not available."
      else if err
        callback err
      else
        callback null, name

  @release =(name, callback=->)->
    @remove {name}, callback

  @claimAll = secure (client, sources, callback=->)->
    unless client.client.connection.delegate.can 'administer names'
      callback new KodingError 'Access denied!'
    else
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
                    @claim doc[usedAsPath], konstructor, usedAsPath, (err)->
                      if err
                        console.log "Couln't claim name #{name}"
                        callback err
                      else if ++j is docCount and ++i is konstructorCount
                        callback null

