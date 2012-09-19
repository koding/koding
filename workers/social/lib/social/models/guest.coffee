jraphical = require 'jraphical'

module.exports = class JGuest extends jraphical.Module

  error =(err)->
    message:
      if 'string' is typeof err
        err
      else
        err.message

  {secure, dash} = require 'bongo'
  
  @share()

  @set
    sharedMethods   :
      static        : ['obtain', 'resetAllGuests']
      instance      : ['on', 'getDefaultEnvironment', 'fetchStorage']
    indexes         :
      guestId       : ['unique', 'descending']
    schema          :
      guestId       :
        required    : yes
        type        : Number
      status        :
        type        : String
        enum        : ['invalid guest status',['pristine','needs cleanup','in use','leasing']]
        default     : 'pristine'
      clientId      : String
      leaseId       : String
      profile       :
        nickname    :
          type      : String
          default   : -> 'Guest'
        firstname   : String
        lastname    : String
        description : String
        avatar      : String
        status      : String

  @resetAllGuests =(client, callback)->
    {delegate} = client.connection
    if delegate.can 'reset guests', =>
      @drop ->
        queue = [0...1e4].map (guestId)->
          guest = new JGuest {guestId}
          guest.save (err)->
            console.log 'saved a guest!'
            queue.fin err
        dash queue, ->
          console.log 'done restting guests!'

  @recycle =(guest, callback=->) ->
    guestId = if guest instanceof @ then guest.getId() else guest
    @update {guestId}, $set:{status: 'needs cleanup'}, callback

  recycle:-> @constructor.recycle this # YAGNI?

  @obtain = secure (client, clientId, callback)->
    [callback, clientId] = [clientId, callback] unless callback
    JAccount = require './account'
    createId = require 'hat'
    {delegate} = client?.connection
    if delegate instanceof JAccount
      callback error 'Logged in user cannot obtain a guest account!'
    else
      leaseId = createId()
      @update {status: 'pristine'}, $set:{status: 'leasing', leaseId}, (err)=>
        if err then callback error err
        else
          @one {leaseId}, (err, guest)=>
            if err then callback error err
            else unless guest?
              callback error "We've reached maximum occupancy for guests.  Please try again later."
            else
              @update {_id:guest.getId()}, {
                $unset    :
                  leaseId : 1
                $set      :
                  status  : 'in use'
              }, (err)->
                if err then callback error err
                else callback null, guest

  fetchStorage: secure (client, options, callback)->
    JAppStorage = require './appstorage'
    callback null, new JAppStorage options