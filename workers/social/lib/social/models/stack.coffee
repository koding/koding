jraphical = require 'jraphical'
module.exports = class JStack extends jraphical.Module

  KodingError        = require '../error'

  {secure, ObjectId, signature} = require 'bongo'
  {Relationship}     = jraphical
  {permit}           = require './group/permissionset'

  @trait __dirname, '../traits/protected'

  @share()

  @set

    softDelete        : yes

    permissions       :
      'create stacks' : ['member']
      'update stacks' : ['member']
      'get stacks'    : ['member']

    sharedMethods     :
      static          :
        one           :
          (signature Object, Function)
        getStack      :
          (signature Function)
        createStack   :
          (signature Function)
        getStacks     :
          (signature Function)
      instance        :
        remove        :
          (signature Function)
        push          :
          (signature Object, Function)

    sharedEvents      :
      static          : [ ]
      instance        : [
        { name : "RemovedFromCollection" }
        { name : 'updateInstance' }
      ]

    schema            :
      user            : String
      group           : String
      sid             : Number
      meta            : Object

  @getStacks = ({user, group}, callback)->

    JStack.some {user, group}, {}, (err, stacks)->
      return callback err  if err
      callback null, stacks or []

  @getStackId = (selector, callback)->

    @getStack selector, (err, stack)->
      callback err, stack?.getId()

  @getStack = ({user, group, sid, meta}, callback)->

    sid ?= 0

    JStack.one {user, group, sid}, (err, stack)->
      return callback err  if err

      if stack
        console.log "Found stack, returning."
        return callback null, stack

      console.log "Stack not found, creating new one."

      stack = new JStack {user, group, sid, meta}
      stack.save (err)->
        if err then callback err
        else callback null, stack

  @createStack = permit 'create stacks',

    success: (client, meta, callback)->

      {group} = client.context
      user    = client.connection.delegate.profile.nickname

      stackCounter = (require 'koding-counter')
        db          : JStack.getClient()
        counterName : "stacks~#{group}~#{user}~"

      stackCounter.next (err, sid)=>
        return callback err  if err
        @getStack {user, group, sid, meta}, callback

  @getStack$ = permit 'get stacks',

    success: (client, callback)->

      {group} = client.context
      user    = client.connection.delegate.profile.nickname

      @getStack {user, group}, callback

  @getStacks$ = permit 'get stacks',

    success: (client, callback)->

      {group} = client.context
      user    = client.connection.delegate.profile.nickname

      @getStacks {user, group}, callback
