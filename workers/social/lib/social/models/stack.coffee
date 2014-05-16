jraphical = require 'jraphical'
module.exports = class JStack extends jraphical.Module

  KodingError        = require '../error'

  {secure, ObjectId, signature} = require 'bongo'
  {Relationship}     = jraphical
  {permit}           = require './group/permissionset'
  Validators         = require './group/validators'

  @trait __dirname, '../traits/protected'

  @share()

  @set

    softDelete           : yes

    permissions          :

      'create stack'     : ['member']

      'update stack'     : []
      'update own stack' : ['member']

      'delete stack'     : []
      'delete own stack' : ['member']

      'list stacks'      : ['member']

    sharedMethods        :
      static             :
        create           :
          (signature Object, Function)
        some             : [
          (signature Object, Function)
          (signature Object, Object, Function)
        ]
      instance           :
        delete           :
          (signature Function)
        modify           :
          (signature Object, Function)

    sharedEvents         :
      static             : [ ]
      instance           : [
        { name : 'updateInstance' }
      ]

    indexes              :
      publicKey          : 'unique'

    schema               :

      title              :
        type             : String
        required         : yes

      originId           :
        type             : ObjectId
        required         : yes

      group              :
        type             : String
        required         : yes

      baseStackId        : ObjectId

      rules              : [ ObjectId ]
      domains            : [ ObjectId ]
      machines           : [ ObjectId ]
      extras             : [ ObjectId ]

      config             : String

      meta               : require 'bongo/bundles/meta'



  ###*
   * JStack::create wrapper for client requests
   * @param  {Mixed}    client
   * @param  {Object}   data
   * @param  {Function} callback
   * @return {void}
  ###
  @create$ = permit 'create stack', success: (client, data, callback)->

    { delegate } = client.connection
    { group    } = client.context

    delete data.baseStackId

    JStack.create { account: delegate, group }, data, callback

  ###*
   * JStack::create
   * @param  {Mixed}   client
   * @param  {Object}   data
   * @param  {Function} callback
   * @return {void}
  ###
  @create = (client, data, callback)->

    { account, group }             = client
    { config, title, baseStackId } = data
    originId = account.getId()

    stack = new JStack {
      title, config, group, originId, baseStackId
    }

    stack.save (err)->
      if err
        msg = "Failed to create stack"
        callback new KodingError msg
        console.warn msg, err
      else
        callback null, stack


  @some$ = permit 'list stacks',

    success: (client, selector, options, callback)->

      [options, callback] = [callback, options]  unless callback
      options ?= {}

      { delegate } = client.connection

      selector         ?= {}
      selector.originId = delegate.getId()

      JStack.some selector, options, callback



  delete: permit

    advanced: [
      { permission: 'delete own stack', validateWith: Validators.own }
    ]

    # TODO Implement walk on domains, machines, rules and delete them too ~ GG

    success: (client, callback)->

      { delegate } = client.connection

      if delegate.getId() is not @originId
        return callback new KodingError "Access denied"

      @remove callback



  modify: permit

    advanced: [
      { permission: 'update own stack', validateWith: Validators.own }
    ]

    success: (client, options, callback)->

      { title, config } = options

      unless title or config
        return callback new KodingError "Nothing to update"

      title  ?= @title
      config ?= @config

      @update $set : { title, config }, (err)->
        return callback err  if err?
        callback null
