{Model} = require 'bongo'

module.exports = class JName extends Model

  KodingError = require '../error'

  {secure, JsPath:{getAt}} = require 'bongo'

  @share()

  @set
    sharedMethods     :
      static          : ['one','claimNames']
    indexes           :
      name            : ['unique']
    schema            :
      name            : String
      constructorName : String
      usedAsPath      : String
      slugs           : [String]

  @release =(name, callback=->)->
    @remove {name}, callback

  @validateName =(candidate)->
    3 < candidate.length < 26 and /^[a-z0-9][a-z0-9-]+$/.test candidate

  @claimNames = secure (client, callback=->)->
    unless client.connection.delegate.can 'administer names'
      callback new KodingError 'Access denied!'
    else
      @claimAll [
        {konstructor: require('./user'),  usedAsPath: 'username'}
        {konstructor: require('./group'), usedAsPath: 'slug'}
      ], callback

  @claim =(fullName, slugs, konstructor, usedAsPath, callback)->
    constructorName =\
      if 'string' is typeof konstructor then konstructor
      else konstructor.fullName
    nameDoc = new this {
      name: fullName
      slugs
      constructorName
      usedAsPath
    }
    nameDoc.save (err)->
      if err?.code is 11000
        err = new KodingError "The fullName #{fullName} is not available."
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
                  name = getAt doc, usedAsPath
                  @claim name, konstructor, usedAsPath, (err)->
                    if err
                      console.log "Couln't claim name #{name}"
                      callback err
                    else if ++j is docCount and ++i is konstructorCount
                      callback null

