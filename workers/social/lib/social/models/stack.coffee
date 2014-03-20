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
          (signature Object, Function)
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
      meta            : Object

  @getStacks = ({user, group}, callback)->

    JStack.some {user, group}, {}, (err, stacks)->
      return callback err  if err

      if stacks.length is 0
        meta = title: "Default", slug: "default"
        JStack.getStack { user, group, meta }, (err, stack) =>
          callback err, [stack]
      else
        callback null, stacks

  @getStackId = (selector, callback)->

    @getStack selector, (err, stack)->
      callback err, stack?.getId()

  @getStack = ({user, group, meta}, callback)->
    JStack.one {user, group, meta}, (err, stack)->
      return callback err  if err

      return callback null, stack  if stack

      stack = new JStack {user, group, meta}
      stack.save (err)->
        if err then callback err
        else callback null, stack

  @createStack = permit 'create stacks',

    success: (client, meta, callback)->

      {group} = client.context
      user    = client.connection.delegate.profile.nickname

      @getStack {user, group, meta}, callback

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
