async     = require 'async'
jraphical = require 'jraphical'


module.exports = class JComputeStack extends jraphical.Module

  KodingError        = require '../error'

  { secure, ObjectId, signature } = require 'bongo'
  { Relationship }   = jraphical
  { uniq }           = require 'underscore'
  { permit }         = require './group/permissionset'
  Validators         = require './group/validators'
  { PROVIDERS }      = require './computeproviders/computeutils'


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
        destroy          :
          (signature Function)
        modify           :
          (signature Object, Function)
        checkRevision    :
          (signature Function)

    sharedEvents         :
      static             : [ ]
      instance           : [
        { name : 'updateInstance' }
      ]

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
        type             : Object
        default          : -> []

      config             : Object

      meta               : require 'bongo/bundles/meta'

      # Identifiers of JCredentials
      # structured like following;
      #  { Provider: [JCredential.identifier ] }
      #  ---
      #  {
      #    aws: [123123, 123124]
      #    github: [234234]
      #  }
      credentials        :
        type             : Object
        default          : -> {}

      status             :

        modifiedAt       : Date
        reason           : String

        state            :
          type           : String
          default        : -> 'NotInitialized'
          enum           : ['Wrong type specified!', [
            # Unknown is a state that needs to be resolved manually
            'Unknown'

            # NotInitialzed defines a state where the stack does not exists and was
            # not built . It's waits to be initialized.
            'NotInitialized'

            # Initialized defines the state where the stack is built and in a functional state
            'Initialized'

            # Destroying is in progress of destroying the stack.
            'Destroying'

            # Building is in progress of creating the stack. A successfull building
            # state results in an Initialized state.
            'Building'
          ]]


  @getStack = (options, callback) ->

    { account, group, stack } = options

    JComputeStack.one {
      _id      : stack
      originId : account.getId()
      group    : group.slug
    }, (err, stackObj) ->

      if err? or not stackObj?
        return callback new KodingError 'A valid stack id required'

      callback null, stackObj


  appendTo: (itemToAppend, callback) ->

    # itemToAppend is like: { machines: machine.getId() }

    # TODO add check for itemToAppend to make sure its just ~ GG
    # including supported fields: [rules, domains, machines, extras]

    @update { $addToSet: itemToAppend }, (err) -> callback err


  ###*
   * JComputeStack::create wrapper for client requests
   * @param  {Mixed}    client
   * @param  {Object}   data
   * @param  {Function} callback
   * @return {void}
  ###
  @create$ = permit 'create stack',

    success: (client, data, callback) ->

      data.account   = client.connection.delegate
      data.groupSlug = client.context.group

      if data.config?
        data.config.groupStack = no

      delete data.baseStackId
      delete data.stackRevision

      JGroup = require './group'

      JGroup.one { slug: data.groupSlug }, (err, group) ->
        return callback err  if err or not group

        updateGroupResourceUsage data, group, 'increment', (err) ->
          return callback err  if err

          JComputeStack.create data, (err, stack) ->
            if err
            then updateGroupResourceUsage data, group, 'decrement', -> callback err
            else callback null, stack


  ###*
   * JComputeStack::create
   * @param  {Object}   data
   * @param  {Function} callback
   * @return {void}
  ###
  @create = (data, callback) ->

    { account, groupSlug, config, credentials
      title, baseStackId, stackRevision } = data

    originId = account.getId()

    stack = new JComputeStack {
      title, config, originId, baseStackId
      stackRevision, credentials
      group: groupSlug
    }

    stack.save (err) ->
      return callback err  if err?
      callback null, stack


  @getSelector = (client, selector) ->

    { delegate } = client.connection
    { group }    = client.context

    selector                ?= {}
    selector.group           = group
    selector.originId        = delegate.getId()
    selector['status.state'] = { $ne: 'Destroying' }

    return selector


  fetchGroup: (callback) ->

    slug   = @getAt 'group'
    JGroup = require './group'
    JGroup.one { slug }, callback


  @some$ = permit 'list stacks',

    success: (client, selector, options, callback) ->

      [options, callback] = [callback, options]  unless callback
      options ?= {}

      selector = @getSelector client, selector

      JComputeStack.some selector, options, (err, _stacks) ->

        if err

          msg = 'Failed to fetch stacks'
          callback new KodingError msg
          console.warn msg, err

        else if not _stacks or _stacks.length is 0

          callback null, []

        else

          callback null, _stacks


  revive: (callback) ->

    JProposedDomain = require './domain'
    JMachine = require './computeproviders/machine'

    queue    = []
    domains  = []
    machines = []

    (@machines ? []).forEach (machineId) ->
      queue.push (next) -> JMachine.one { _id: machineId }, (err, machine) ->
        if not err? and machine
          machines.push machine
        next()

    (@domains ? []).forEach (domainId) ->
      queue.push (next) -> JProposedDomain.one { _id: domainId }, (err, domain) ->
        if not err? and domain
          domains.push domain
        next()

    async.series queue, =>
      this.machines = machines
      this.domains = domains
      callback null, this


  unuseStackTemplate: (callback) ->

    # TMS-1919: We currently have one-to-one relation between user and any
    # given stack template, if we need to allow users to use same stack
    # multiple times (which I don't think we should do) we need to change
    # this behaviour here and the rest of the code ~ GG

    Relationship.remove
      targetName : 'JStackTemplate'
      targetId   : @baseStackId
      sourceId   : @originId
      sourceName : 'JAccount'
      as         : 'user'
    , callback


  updateGroupResourceUsage = (stack, group, change, callback) ->

    ComputeProvider = require './computeproviders/computeprovider'
    instanceCount   = (stack.getAt?('machines') ? stack.machines ? []).length

    ComputeProvider.updateGroupResourceUsage {
      group, change, instanceCount
    }, callback


  destroy: (callback) ->

    @fetchGroup (err, group) =>
      return callback err  if err

      @update { $set: { status: { state: 'Destroying' } } }, (err) =>
        return callback err  if err

        JMachine = require './computeproviders/machine'

        updateGroupResourceUsage this, group, 'decrement', =>

          machineIds = (machineId for machineId in @machines)

          JMachine.update
            _id   :
              $in : machineIds
          ,
            $set  :
              'status.state' : 'Terminated'
              'users'        : [] # remove users from machines since it's going
                                  # to be terminated so users of this
                                  # machine won't be able to see it ~ GG
          , { multi : yes }
          , (err) =>

            if err
              console.warn 'Failed to mark stack machines as Terminated:', err

            @unuseStackTemplate callback


  delete: (callback) ->

    if @baseStackId
      return callback new KodingError \
        'Stacks generated from templates can only be destroyed by Kloud.'

    @fetchGroup (err, group) =>

      return callback err  if err

      @update { $set: { status: { state: 'Destroying' } } }

      JProposedDomain  = require './domain'
      JMachine = require './computeproviders/machine'

      @domains?.forEach (_id) ->
        JProposedDomain.one { _id }, (err, domain) ->
          if not err? and domain?
            domain.remove (err) ->
              if err then console.error \
                "Failed to remove domain: #{domain.domain}", err

      @machines?.forEach (_id) ->
        JMachine.one { _id }, (err, machine) ->
          if not err? and machine?
            machine.remove (err) ->
              if err then console.error \
                "Failed to remove machine: #{machine.title}", err

      @destroy => @remove callback


  delete$: permit

    # TODO Add password check for stack delete
    #

    advanced: [
      { permission: 'delete own stack', validateWith: Validators.own }
    ]

    success: (client, callback) ->

      @delete callback


  destroy$: permit

    advanced: [
      { permission: 'delete own stack', validateWith: Validators.own }
    ]

    success: (client, callback) ->

      @destroy callback


  SUPPORTED_CREDS = (Object.keys PROVIDERS).concat ['userInput', 'custom']

  modify: permit

    advanced: [
      { permission: 'update own stack', validateWith: Validators.own }
    ]

    success: (client, options, callback) ->

      { title, config, credentials } = options

      unless title or config or credentials
        return callback new KodingError 'Nothing to update'

      dataToUpdate        = {}
      dataToUpdate.title  = title   if title?
      dataToUpdate.config = config  if config?

      if credentials?
        unless typeof credentials is 'object'
          return callback new KodingError 'Credential should be an Object'

        sanitized = {}
        for key, value of credentials
          if key in SUPPORTED_CREDS
            sanitized[key] = uniq value

        dataToUpdate.credentials = sanitized

      @update { $set : dataToUpdate }, (err) ->
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

      JStackTemplate = require './computeproviders/stacktemplate'
      JStackTemplate.one { _id: @baseStackId }, (err, template) =>
        return callback err  if err
        return callback new KodingError 'Template not valid'  unless template

        status =
          if not template?.template?.sum or not @stackRevision
            stackRevisionErrors.INVALIDTEMPLATE
          else if template.template.sum is @stackRevision
            stackRevisionErrors.TEMPLATESAME
          else
            stackRevisionErrors.TEMPLATEDIFFERENT

        callback null, { status, machineCount: template.machines.length }
