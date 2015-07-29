jraphical = require 'jraphical'


module.exports = class JComputeStack extends jraphical.Module

  KodingError        = require '../error'

  {secure, ObjectId, signature, daisy} = require 'bongo'
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
        checkRevision     :
          (signature Function)

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
      stackRevision      : String

      machines           :
        type             : [ ObjectId ]
        default          : -> []

      config             : Object

      meta               : require 'bongo/bundles/meta'

      status             :
        type             : String
        enum             : ["Wrong type specified!", [

          # States which description ending with '...' means its an ongoing
          # proccess which you may get progress info about it
          #
          "Initial"         # Initial state
          "Terminating"     # Stack is getting destroyed...
          "Terminated"      # Stack is destroyed, not exists anymore
        ]]

        default          : -> "Initial"


  @getStack = (account, _id, callback)->

    JComputeStack.one { _id, originId : account.getId() }, (err, stackObj)->
      if err? or not stackObj?
        return callback new KodingError "A valid stack id required"
      callback null, stackObj


  appendTo: (itemToAppend, callback)->

    # itemToAppend is like: { machines: machine.getId() }

    # TODO add check for itemToAppend to make sure its just ~ GG
    # including supported fields: [rules, domains, machines, extras]

    @update $addToSet: itemToAppend, (err)-> callback err


  ###*
   * JComputeStack::create wrapper for client requests
   * @param  {Mixed}    client
   * @param  {Object}   data
   * @param  {Function} callback
   * @return {void}
  ###
  @create$ = permit 'create stack', success: (client, data, callback)->

    data.account   = client.connection.delegate
    data.groupSlug = client.context.group

    delete data.baseStackId
    delete data.stackRevision

    JComputeStack.create data, callback


  ###*
   * JComputeStack::create
   * @param  {Object}   data
   * @param  {Function} callback
   * @return {void}
  ###
  @create = (data, callback)->

    { account, groupSlug, config, title, baseStackId, stackRevision } = data

    originId = account.getId()

    stack = new JComputeStack {
      title, config, originId, baseStackId, stackRevision
      group: groupSlug
    }

    stack.save (err)->
      return callback err  if err?
      callback null, stack


  @getSelector = (client, selector)->

    { delegate } = client.connection
    { group }    = client.context

    selector ?= {}
    selector.originId = delegate.getId()
    selector.status   = $ne: "Terminated"
    selector.group    = group

    return selector


  @some$ = permit 'list stacks',

    success: (client, selector, options, callback)->

      [options, callback] = [callback, options]  unless callback
      options ?= {}

      selector = @getSelector client, selector


      JComputeStack.some selector, options, (err, _stacks)->

        if err

          msg = "Failed to fetch stacks"
          callback new KodingError msg
          console.warn msg, err

        else if not _stacks or _stacks.length is 0

          callback null, []

        else

          callback null, _stacks

          # stacks = []

          # queue = _stacks.map (stack) -> ->
          #   stack.revive (err, revivedStack)->
          #     stacks.push revivedStack
          #     queue.next()

          # queue.push ->
          #   callback null, stacks

          # daisy queue



  revive: (callback)->

    JProposedDomain = require "./domain"
    JMachine = require "./computeproviders/machine"

    queue    = []
    domains  = []
    machines = []

    (@machines ? []).forEach (machineId)->
      queue.push -> JMachine.one _id: machineId, (err, machine)->
        if not err? and machine
          machines.push machine
        queue.next()

    (@domains ? []).forEach (domainId)->
      queue.push -> JProposedDomain.one _id: domainId, (err, domain)->
        if not err? and domain
          domains.push domain
        queue.next()

    queue.push =>
      this.machines = machines
      this.domains = domains
      callback null, this

    daisy queue


  delete: permit

    # TODO Add password check for stack delete
    #

    advanced: [
      { permission: 'delete own stack', validateWith: Validators.own }
    ]

    success: (client, callback)->

      # TODO Implement delete methods.
      @update $set: status: "Terminating"

      JProposedDomain  = require "./domain"
      JMachine = require "./computeproviders/machine"

      { delegate } = client.connection

      @domains?.forEach (_id)->
        JProposedDomain.one {_id}, (err, domain)->
          if not err? and domain?
            domain.remove (err)->
              if err then console.error \
                "Failed to remove domain: #{domain.domain}", err

      @machines?.forEach (_id)->
        JMachine.one {_id}, (err, machine)->
          if not err? and machine?
            machine.remove (err)->
              if err then console.error \
                "Failed to remove machine: #{machine.title}", err

      Relationship.remove {
        targetName : "JStackTemplate"
        targetId   : @baseStackId
        sourceId   : delegate.getId()
        sourceName : "JAccount"
        as         : "user"
      }, (err)=>

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


  stackRevisionErrors =
    TEMPLATESAME      :
      message         : 'Base stack template is same'
      code            : 0
    TEMPLATEDIFFERENT :
      message         : 'Base stack template is different'
      code            : 1
    NOTFROMTEMPLATE   :
      message         : 'This stack is not created from a template'
      code            : 2
    INVALIDTEMPLATE   :
      message         : 'This stack has no revision or template is not valid.'
      code            : 3


  checkRevision: permit

    advanced: [
      { permission: 'list stacks', validateWith: Validators.own }
    ]

    success: (client, callback) ->

      if not @baseStackId
        return callback null, stackRevisionErrors.NOTFROMTEMPLATE

      JStackTemplate = require "./computeproviders/stacktemplate"
      JStackTemplate.one { _id: @baseStackId }, (err, template) =>
        return callback err  if err
        return callback new KodingError "Template not valid"  unless template

        status =
          if not template?.template?.sum or not @stackRevision
            stackRevisionErrors.INVALIDTEMPLATE
          else if template.template.sum is @stackRevision
            stackRevisionErrors.TEMPLATESAME
          else
            stackRevisionErrors.TEMPLATEDIFFERENT

        callback null, { status, machineCount: template.machines.length }
