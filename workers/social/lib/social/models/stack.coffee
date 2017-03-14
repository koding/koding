async     = require 'async'
jraphical = require 'jraphical'

stackRevisionErrors = require './stackrevisionerrors'

# JComputeStack keeps stack data
# including machines and credential references
#
# @example
#
#   stack = new JComputeStack {
#     title: 'test stack'
#     machines: [Array<JMachine._id>]
#   }
#
module.exports = class JComputeStack extends jraphical.Module

  KodingError        = require '../error'

  { secure, ObjectId, signature } = require 'bongo'
  { Relationship }   = jraphical
  { uniq }           = require 'underscore'
  { permit }         = require './group/permissionset'
  Validators         = require './group/validators'

  { PROVIDERS, reviveGroupLimits } = require './computeproviders/computeutils'

  @trait __dirname, '../traits/protected'

  @share()

  @set

    indexes              :
      baseStackId        : 'sparse'

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
        one              : [
          (signature Object, Function)
          (signature Object, Object, Function)
        ]
        some             : [
          (signature Object, Function)
          (signature Object, Object, Function)
        ]
      instance           :
        delete           :
          (signature Function)
        maintenance      :
          (signature Object, Function)
        destroy          :
          (signature Function)
        modify           :
          (signature Object, Function)
        checkRevision    :
          (signature Function)
        createAdminMessage :
          (signature String, String, Function)
        deleteAdminMessage :
          (signature Function)

    sharedEvents         :
      static             : []
      instance           : []

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

  @create$ = permit 'create stack',

    success: (client, data, callback) ->

      unless client.context?.group or client.connection?.delegate
        return callback new KodingError 'Session is not valid'

      data.account   = client.connection.delegate
      data.groupSlug = client.context.group

      if data.config?
        data.config.groupStack = no

      delete data.baseStackId
      delete data.stackRevision

      JComputeStack.fetchGroup data.groupSlug, (err, group) ->
        return callback err  if err or not group

        updateGroupResourceUsage data, group, 'increment', (err) ->
          return callback err  if err

          JComputeStack.create data, (err, stack) ->
            if err
            then updateGroupResourceUsage data, group, 'decrement', -> callback err
            else callback null, stack


  # JComputeStack::create
  #
  # @param {Object} data
  #   Data needs to provide default schema of JComputeStack
  #   `data = { config, credentials, title }`
  #
  # @option data [String] title stack title
  # @option data [Object] config details for stack
  # @option data [Object] credentials list of credentials that is needed for stack
  #
  # @return {JComputeStack} created JComputeStack instance
  #
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
      stack.notifyAdmins 'StackCreated'
      callback null, stack


  @getSelector = (client, selector) ->

    { delegate } = client.connection
    { group }    = client.context

    selector                ?= {}
    selector.group           = group
    selector.originId        = delegate.getId()
    selector['status.state'] = { $ne: 'Destroying' }

    return selector


  @fetchGroup = (slug, callback) ->

    JGroup = require './group'
    JGroup.one { slug }, (err, group) ->
      reviveGroupLimits group, callback


  fetchGroup: (callback) ->

    JComputeStack.fetchGroup @getAt('group'), callback


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


  @one$: permit 'list stacks',

    success: (client, selector, options, callback) ->

      [options, callback] = [callback, options]  unless callback

      options ?= {}
      options.limit = 1

      @some$ client, selector, options, (err, stacks) ->
        return callback err  if err

        [ stack ] = stacks ? []
        if stack
        then stack.revive client, callback
        else callback null


  revive: (client, callback) ->

    JMachine = require './computeproviders/machine'
    JAccount = require './account'

    queue    = []
    machines = []

    (@machines ? []).forEach (machineId) ->
      queue.push (next) -> JMachine.one { _id: machineId }, (err, machine) ->
        if not err? and machine
          machines.push machine
        next()

    async.series queue, =>

      JAccount.one { _id: @getAt 'originId' }, (err, owner) =>

        return callback err  if err

        this.owner    = owner ? { error: 'Owner not exists' }
        this.machines = machines

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
    , (err) -> callback err


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


  delete: (callback, force = no) ->

    if @baseStackId and not force
      return callback new KodingError \
        'Stacks generated from templates can only be destroyed by Kloud.'

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


  maintenance: permit

    advanced: [
      { permission: 'delete stack' }
      { permission: 'delete stack', superadmin: yes }
    ]

    success: (client, options, callback) ->

      if client.context.group isnt @getAt 'group'
        return callback new KodingError 'Access denied'

      if options.destroyStack

        @unuseStackTemplate (err) =>
          return callback err  if err
          @delete callback, force = yes

      else if options.prepareForDestroy

        JMachine = require './computeproviders/machine'

        queue = []
        @machines?.forEach (_id) -> queue.push (next) ->
          JMachine.update { _id }, { $set: { users: [] } }, next

        async.series queue, (err) =>
          return callback err  if err
          @update { $set: { status: { state: 'Initialized' } } }, callback

      else if options.prepareForMount and machineId = options.machineId

        if machineId not in ("#{m}" for m in @getAt 'machines')
          return callback new KodingError 'Machine not in this stack'

        { connection: { delegate } } = client
        { profile: { nickname } }    = delegate

        group = @getAt 'group'

        JMachine = require './computeproviders/machine'
        JMachine.one { _id: machineId }, (err, machine) ->

          if err or not machine
            return callback err ? new KodingError 'Machine not found'

          shareOptions = {
            target     : [ nickname ]
            permanent  : yes
            group
          }

          machine.shareWith shareOptions, callback

      else

        callback new KodingError 'Please provide a vaild maintenance mode'


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
      { permission: 'delete stack' }
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

        status = @checkRevisionByTemplate template

        callback null, { status, machineCount: template.machines.length }


  checkRevisionByTemplate: (template) ->

    if not @baseStackId
      return stackRevisionErrors.NOTFROMTEMPLATE

    if not template?.template?.sum or not @stackRevision
      return stackRevisionErrors.INVALIDTEMPLATE

    if template.template.sum is @stackRevision
      return stackRevisionErrors.TEMPLATESAME

    return stackRevisionErrors.TEMPLATEDIFFERENT


  createAdminMessage: (message, type, callback) ->

    config              = @getAt 'config'
    config.adminMessage = { message, type }
    @update { $set : { config } }, callback


  createAdminMessage$: permit

    advanced: [
      { permission: 'update stack', validateWith: Validators.group.admin }
    ]

    success: (client, message, type, callback) ->

      @createAdminMessage message, type, (err) =>
        callback err  if err

        JGroup = require './group'
        JGroup.sendStackAdminMessageNotification {
          slug     : @group
          stackIds : [ @_id ]
          message
          type
        }, callback


  deleteAdminMessage: (callback) ->

    config              = @getAt 'config'
    config.adminMessage = null
    @update { $set : { config } }, callback


  deleteAdminMessage$: permit

    advanced: [
      { permission: 'update own stack', validateWith: Validators.own }
    ]

    success: (client, callback) ->

      @deleteAdminMessage callback


  notifyAdmins: (subject) ->

    @fetchGroup (err, group) =>
      return console.log err  if err

      { notifyAdmins } = require './notify'
      notifyAdmins group, subject,
        id    : @_id
        group : group.slug
