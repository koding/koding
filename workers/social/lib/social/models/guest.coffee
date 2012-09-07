jraphical = require 'jraphical'

module.exports = class JGuest extends jraphical.Module
  
  {secure} = require 'bongo'
  
  @share()
  
  counter = 0
  
  @hose {guestId: 1}, {limit: 1, sort: guestId: -1}, (err, cursor)->
    cursor?.nextObject (err, obj)->
      counter = unless isNaN obj?.guestId then obj.guestId + 1 else 0

  @set
    sharedMethods   :
      instance      : ['on', 'getDefaultEnvironment', 'fetchStorage']
    indexes         :
      guestId       : ['unique', 'descending']
    schema          :
      guestId       :
        type        : Number
        default     : -> counter++
      clientId      : String
      profile       :
        nickname    :
          type      : String
          default   : -> 'Guest'
        firstname   : String
        lastname    : String
        description : String
        avatar      : String
        status      : String
    
  fetchStorage: secure (client, options, callback)->
    callback null, new JAppStorage options