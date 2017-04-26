{ Base, secure, signature } = require 'bongo'

KONFIG       = require 'koding-config-manager'
async        = require 'async'
_            = require 'lodash'
konstraints  = require 'konstraints'

teamutils    = require './teamutils'
KodingError  = require '../../error'
KodingLogger = require '../kodinglogger'

MAX_INT      = Math.pow(2, 32) - 1

helpers      = require './helpers'

# Base class for compute related operations
#
module.exports = class ComputeProvider extends Base

  {
    PLANS, PROVIDERS, fetchGroupStackTemplate, revive, checkTemplateUsage
  } = require './computeutils'

  @trait __dirname, '../../traits/protected'

  { permit } = require '../group/permissionset'

  JMachine       = require './machine'

  @COUNTER_TYPE  = {
    stacks       : 'member_stacks'
    instances    : 'member_instances'
  }

  @share()

  @set
    permissions           :
      'sudoer'            : []
      'ping machines'     : ['member', 'moderator']
      'list machines'     : ['member', 'moderator']
      'create machines'   : ['member', 'moderator']
      'delete machines'   : ['member', 'moderator']
      'update machines'   : ['member', 'moderator']
      'list own machines' : ['member', 'moderator']
    sharedMethods         :
      static              :
        ping              :
          (signature Object, Function)
        create            :
          (signature Object, Function)
        remove            :
          (signature Object, Function)
        update            :
          (signature Object, Function)
        fetchAvailable    :
          (signature Object, Function)
        fetchProviders    :
          (signature Function)
        createGroupStack  :
          (signature Function)
        updateTeamCounters:
          (signature String, Function)
        setGroupStack     :
          (signature Object, Function)


  @providers      = PROVIDERS


  @fetchProviders = secure (client, callback) ->
    callback null, Object.keys _.pickBy PROVIDERS, (x) -> x.supportsStacks


  # pings to requested provider implementation
  #
  # @param {Object} options
  #   generic options for ComputeProvider calls should include
  #   the provider slug as parameter
  #
  # @option options [String] provider provider slug
  #
  # @example api
  #
  #   {
  #     "provider": "aws"
  #   }
  #
  @ping = (client, options, callback) ->

    { provider } = options
    provider.ping client, options, callback


  @ping$ = permit 'ping machines',
    success: revive {
      shouldReviveClient   : yes
      shouldPassCredential : no
    }, @ping


  # creates a JMachine for requested provider with the provided options
  #
  # @param {Object} options
  #   generic options for ComputeProvider calls should include
  #   the provider slug as parameter
  #
  # @option options [String] provider provider slug
  #
  # @return {JMachine} created JMachine instance
  #
  # @example api
  #
  #   {
  #     "provider": "aws",
  #     "label": "My new Machine",
  #     "stack": "ID_OF_TARGET_STACK",
  #     "credential": "ID_OF_CREDENTIAL",
  #     "meta": {
  #       "instance_type": "t2.micro",
  #       "region": "us-east-1",
  #       "image": "ami-XXXX",
  #       "storage_size": 10
  #     }
  #   }
  #
  @create = ->
  @create = revive

    shouldReviveClient       : yes
    shouldReviveProvisioners : yes
    shouldFetchGroupLimit    : yes

  , (client, options, callback) ->

    { provider, stack, label, provisioners, users, generatedFrom } = options
    { r: { group, user, account } } = client

    provider.create client, options, (err, machineData) ->

      return callback err  if err

      { meta, postCreateOptions, credential } = machineData

      label ?= machineData.label

      JMachine.create {
        provider : provider.slug
        label, meta, group, user, generatedFrom
        users, credential, provisioners
      }, (err, machine) ->

        # TODO if any error occurs here which means user paid for
        # not created vm ~ GG
        return callback err  if err

        provider.postCreate client, {
          postCreateOptions, machine, meta, stack: stack._id
        }, (err) ->

          return callback err  if err

          stack.appendTo { machines: machine.getId() }, (err) ->
            callback err, machine


  @create$ = permit 'create machines', { success: revive

    shouldReviveClient   : yes
    shouldPassCredential : yes
    shouldReviveProvider : no
    shouldLockProcess    : yes
    shouldFetchGroupLimit : yes

  , (client, options, callback) ->

    { r: { account, group } } = client
    { stack } = options

    JComputeStack = require '../stack'
    JComputeStack.getStack { account, group, stack }, (err, revivedStack) =>
      return callback err  if err?
      return callback new KodingError 'No such stack'  unless revivedStack

      options.stack = revivedStack

      # Reset it here if someone tries to put users
      # from client side request
      options.users = []

      # Remove generatedFrom option if provided
      delete options.generatedFrom

      @create client, options, callback
  }


  @fetchAvailable = secure revive

    shouldReviveClient   : no
    shouldPassCredential : yes

  , (client, options, callback) ->

    { provider } = options
    provider.fetchAvailable client, options, callback


  @update = secure revive

    shouldReviveClient   : yes
    shouldPassCredential : yes

  , (client, options, callback) ->

    { provider } = options
    provider.update client, options, callback


  @remove = secure revive

    shouldReviveClient   : yes
    shouldPassCredential : yes

  , (client, options, callback) ->

    { provider } = options
    provider.remove client, options, callback


  addGroupAdmin = (group, machineInfo, callback) ->

    # TODO Do we need all admins or only some of them? ~ GG
    # Maybe some of them as admin some of them as user etc.
    group.fetchAdmin (err, admin) ->

      if not err and admin and not admin.getId().equals account.getId()
        admin.fetchUser (err, adminUser) ->
          if not err and adminUser
            machineInfo.users = [{
              id       : adminUser.getId(),
              username : adminUser.username,
              sudo     : yes, owner: yes
            }]
          callback machineInfo
      else
        callback machineInfo


  @generateStackFromTemplate = (data, options, callback) ->

    { account, user, group, template, client } = data

    stackRevision = template.template?.sum or ''

    JComputeStack = require '../stack'

    # To be able to mark a generated stack as group stack
    # we need to iterate over existing stacks defined for group
    # and mark this one as groupStack or not.
    #
    # We eventually remove this one once we remove group stack flow ~ GG
    config = _.clone template.config
    for _template in (group.stackTemplates ? [])
      if template._id.equals _template
        config.groupStack = yes
        break

    # Create a new JComputeStack based on the template details
    # We will then add machines and other information into it.
    JComputeStack.create {
      title         : template.title
      config        : config
      credentials   : template.credentials
      baseStackId   : template._id
      groupSlug     : group.slug
      account, stackRevision
    }, (err, stack) ->

      return callback err  if err

      queue         = []
      results       =
        machines    : []

      # Create JMachine documents based on the data
      # provided in template's machines array ~ GG
      template.machines?.forEach (machineInfo) ->

        queue.push (next) ->

          # Set the stack as newly create JComputeStack
          machineInfo.stack         = stack

          # We are passing the provided credential for the template
          # Provider implementation can override this value like we
          # did in Koding Provider ~ GG
          machineInfo.credential    =
            template.credentials?[machineInfo.provider]?.first

          machineInfo.generatedFrom =
            templateId : template._id
            revision   : stackRevision

          # Inline create helper
          create = (machineInfo) ->
            ComputeProvider.create client, machineInfo, (err, machine) ->
              results.machines.push { err, obj: machine }
              next()

          # This is optional, since for koding group for example
          # we don't want to add our admins into users machines ~ GG
          if options.addGroupAdminToMachines
            addGroupAdmin group, machineInfo, (_machine) -> create _machine
          else
            create machineInfo

      async.series queue, -> callback null, { stack, results }


  # Just takes the limit config and the stack template content generates rules
  # based on the limits then verifies the content based on the rules generated
  @validateTemplateContent = (content, limitConfig, callback) ->

    try
      template = JSON.parse content
    catch
      return callback new KodingError 'Template is not valid'

    teamutils.fetchConstraints limitConfig, (err, rules) ->

      { passed, results } = konstraints template, rules, {}
      return callback new KodingError results.last[1]  unless passed

      return callback null


  # Template checker, this will fetch the stack template from given id,
  # will generate konstraint rules based on the group's limit and finally
  # validate the stack template based on these informations ~ GG
  @validateTemplate = (client, stackTemplateId, group, callback) ->

    limitConfig = helpers.getLimitConfig group

    return callback null  unless limitConfig.limit

    JStackTemplate = require './stacktemplate'
    JStackTemplate.one$ client, { _id: stackTemplateId }, (err, data) =>

      return callback err  if err
      return callback new KodingError 'Stack template not found'  unless data

      @validateTemplateContent data.template.content, limitConfig, callback


  # Takes an array of stack template ids and returns the final result ^^
  @validateTemplates = (client, stackTemplates, group, callback) ->

    queue = []

    stackTemplates.forEach (stackTemplateId) -> queue.push (next) ->
      ComputeProvider.validateTemplate client, stackTemplateId, group, (err) ->
        return callback err  if err
        next()

    async.series queue, -> callback null


  @destroyAccountResources = (account, callback) ->

    skip = (type, next) -> (err) ->
      console.log "[#{type}] Failed to destroy account resource:", err  if err
      next()

    async.series [

      # Remove all machines associated with account
      (next) ->
        JMachine.remove {
          users: { $elemMatch: { username: account.getAt('profile.nickname'), sudo: yes, owner: yes } }
        }, skip 'JMachine', next

      # Remove all stacks associated with account
      (next) ->
        JComputeStack = require '../stack'
        JComputeStack.remove {
          originId: account.getId()
        }, skip 'JComputeStack', next

      # Remove all stack templates associated with account
      (next) ->
        JStackTemplate = require './stacktemplate'
        JStackTemplate.remove {
          originId: account.getId()
        }, skip 'JStackTemplate', next

    ], ->

      callback null


  # WARNING! This will destroy all the resources related with given group!
  #
  # We are just logging all errors in this flow, and not interrupting
  # anything since this shouldn't prevent to destroy group operation ~ GG
  #
  @destroyGroupResources = (group, callback) ->

    skip = (type, next) -> (err) ->
      console.log "[#{type}] Failed to destroy group resource:", err  if err
      next()

    async.series [

      # Remove all machines in the group
      (next) ->
        JMachine.remove {
          groups: { $elemMatch: { id: group.getId() } }
        }, skip 'JMachine', next

      # Remove all stacks in the group
      (next) ->
        JComputeStack = require '../stack'
        JComputeStack.remove {
          group: group.slug
        }, skip 'JComputeStack', next

      # Remove all stack templates in the group
      (next) ->
        JStackTemplate = require './stacktemplate'
        JStackTemplate.remove {
          group: group.slug
        }, skip 'JStackTemplate', next

      # Remove all counters
      (next) ->
        JCounter = require '../counter'
        JCounter.remove {
          namespace: group.slug
        }, skip 'JCounter', next

    ], ->

      callback null


  # Auto create stack operations ###

  @createGroupStack$ = permit 'create machines',

    success: (client, callback) ->

      ComputeProvider.createGroupStack client, callback


  @updateGroupStackUsage = (group, change, callback) ->

    return callback null  if group.slug is 'koding'

    limitConfig = helpers.getLimitConfig group

    teamutils.fetchLimitData limitConfig, (err, limits) =>

      return callback err  if err

      maxAllowed = limits.member ? MAX_INT

      JCounter = require '../counter'
      JCounter[change]
        namespace : group.getAt 'slug'
        type      : @COUNTER_TYPE.stacks
        max       : maxAllowed
        min       : 0
      , (err) ->
        # no worries about `decrement` errors
        # since 0 is already defined as min ~ GG
        callback if change is 'increment' then err else null


  @updateGroupInstanceUsage = (options, callback) ->

    { group, change, amount } = options

    # We don't need to do anything if amount somehow is 0
    # A stack template without machines in it? ~ GG
    return callback null  if group.slug is 'koding' or amount is 0

    limitConfig  = helpers.getLimitConfig group
    maxAllowed   = MAX_INT

    teamutils.fetchLimitData limitConfig, (err, limits) =>

      return callback err  if err

      maxAllowed = limits.maxInstance  if limits

      JCounter = require '../counter'
      JCounter[change]
        namespace : group.getAt 'slug'
        amount    : amount
        type      : @COUNTER_TYPE.instances
        max       : maxAllowed
        min       : 0
      , (err) ->
        # no worries about `decrement` errors
        # since 0 is already defined as min ~ GG
        callback if change is 'increment' then err else null


  @updateGroupResourceUsage = (options, callback) ->

    { notifyAdmins } = require '../notify'
    { group, instanceCount, instanceOnly, change, details } = options

    return callback null  if group.slug is 'koding'

    handleResult = (err, item) ->

      if err and change is 'increment'

        { account, template, provider } = details ? {}
        user     = account?.getAt?('profile.nickname') ? 'an unknown user'
        provider = if provider? then "#{provider} " else ''
        template = if template?.title?
        then "Stack: #{template.title} - #{template._id}"
        else ''

        message = "
          #{user} failed to create #{provider}#{item} due to
          limitations. #{template}
        "

        KodingLogger.warn group, message
        notifyAdmins group, 'MemberWarning', message

      callback err

    options = { group, change, amount: instanceCount }

    if instanceOnly
      @updateGroupInstanceUsage options, (err) ->
        handleResult err, 'machine'

      return

    @updateGroupStackUsage group, change, (err) =>
      return handleResult err, 'stack'  if err

      @updateGroupInstanceUsage options, (err) =>
        if err and change is 'increment'
          @updateGroupStackUsage group, 'decrement', ->
            handleResult err, 'machine'
        else
          handleResult err, 'resource'


  @updateTeamCounters$ = permit
    advanced : [{ permission: 'sudoer', superadmin: yes }]
    success  : (client, team, callback) ->
      ComputeProvider.updateTeamCounters team, callback


  @updateTeamCounters = (team, callback) ->

    return callback new KodingError 'Team slug is required'  unless team

    JGroup        = require '../group'
    JCounter      = require '../counter'
    JComputeStack = require '../stack'

    COUNTER_TYPE  = @COUNTER_TYPE

    async.waterfall [

      (next) ->

        JGroup.one { slug: team }, (err, group) ->
          if err or not group
            err ?= new KodingError 'Team not found'
          next err, group

      (group, next) ->

        options = { namespace: group.slug, type: COUNTER_TYPE.stacks }
        JCounter.count options, (err, count = 0) ->
          next err, group, count

      (group, stackCount, next) ->

        options = { namespace: group.slug, type: COUNTER_TYPE.instances }
        JCounter.count options, (err, count = 0) ->
          next err, group, stackCount, count

      (group, stackCount, machineCount, next) ->

        changes   =
          before  : { stacks: stackCount, instances: machineCount }
          current : {}
          after   : {}

        JComputeStack.count {
          'status.state' : { $ne: 'Destroying' }
          group          : group.slug
        }, (err, count) ->
          changes.current.stacks = count
          next err, group, changes

      (group, changes, next) ->

        JMachine.count {
          'status.state' : { $nin       : [ 'Terminated', 'Terminating' ] }
          groups         : { $elemMatch : { id: group.getId() } }
        }, (err, count) ->
          changes.current.instances = count
          next err, group, changes

      (group, changes, next) ->

        options     = {
          namespace : group.slug
          type      : COUNTER_TYPE.stacks
          value     : changes.current.stacks
        }

        JCounter.setCount options, (err, count) ->
          changes.after.stacks = count
          next err, group, changes

      (group, changes, next) ->

        options     = {
          namespace : group.slug
          type      : COUNTER_TYPE.instances
          value     : changes.current.instances
        }

        JCounter.setCount options, (err, count) ->
          changes.after.instances = count
          next err, changes

    ], callback


  @fetchGroupResources = (client, group, selector, options, callback) ->

    selector ?= {}
    selector.$and ?= []
    selector.$and.push { group: group.slug }

    options ?= {}
    options.limit = Math.min 20, options.limit

    mainQueue = [
      (next) ->
        JComputeStack = require '../stack'
        JComputeStack.some selector, options, (err, stacks) ->
          return next err  if err

          if stacks?.length > 0
            reviveQueue = []
            stacks.forEach (stack) ->
              reviveQueue.push (next) -> stack.revive client, next
            async.parallel reviveQueue, -> next null, stacks
          else
            next null, []
      (stacks, next) ->
        return next null, []  unless stacks.length

        templateIds = stacks.map (stack) -> stack.baseStackId

        JStackTemplate = require './stacktemplate'
        JStackTemplate.some { _id: { $in: templateIds } }, {}, (err, templates) ->
          return next err  if err

          for stack in stacks
            template = templates.filter(
              (template) -> template._id.equals stack.baseStackId
            )[0]
            continue  unless template
            stack.checkRevisionResult = stack.checkRevisionByTemplate template

          next null, stacks
    ]

    async.waterfall mainQueue, callback


  @createGroupStack = (client, options, callback) ->

    unless callback
      [options, callback] = [callback, options]

    callback     ?= ->
    options      ?= {}
    res           = {}
    instanceCount = 0
    createdStack  = null

    { template, account, group } = {}

    # TMS-1919: A similar method needs to be written (or this one needs to
    # be updated) to allow users to provide any stackTemplate to create a stack
    # from it (::generateStackFromTemplate)
    # We then need to check if they are eligible to use that stack template,
    # we need to check limits for the current group and create the stack and
    # related machines here, this is very critical for multiple stacks ~ GG

    async.series [

      (next) ->
        fetchGroupStackTemplate client, (err, _res) ->
          unless err
            { template, account, group } = res = _res
          next err

      (next) ->
        instanceCount = template.machines?.length or 0
        change        = 'increment'

        details = { template, account }

        ComputeProvider.updateGroupResourceUsage {
          group, change, instanceCount, details
        }, (err) ->
          next err

      (next) ->
        checkTemplateUsage template, account, (err) ->
          return next err  if err
          account.addStackTemplate template, (err) ->
            res.client = client
            next err

      (next) ->

        # Marking this as groupStack to use it with group resources ~ GG
        res.template.config ?= {}
        res.template.config.groupStack = yes

        ComputeProvider.generateStackFromTemplate res, options, (err, stack) ->

          if err
            # swallowing errors for followings since we need the real error ~GG
            account.removeStackTemplate template, ->
              ComputeProvider.updateGroupResourceUsage {
                group, change: 'decrement', instanceCount
              }, -> next err
            return

          createdStack = stack

          { machines = [] } = stack?.results ? []
          if failedMachines = (machines.filter (m) -> m.err).length
            ComputeProvider.updateGroupResourceUsage {
              instanceCount: failedMachines
              instanceOnly: yes
              change: 'decrement'
              group
            }, (err) ->
              next err
          else
            next()

    ], (err) ->
      callback err, createdStack


  @forceStacksToReinit = (template, message, callback) ->

    JComputeStack       = require '../stack'
    stackRevisionErrors = require '../stackrevisionerrors'
    JComputeStack.some { baseStackId : template._id }, {}, (err, stacks) ->
      return callback err  if err
      return callback()  unless stacks.length

      queue    = []
      stackIds = []
      type     = 'forcedReinit'
      stacks.forEach (stack) ->
        checkResult = stack.checkRevisionByTemplate template
        if checkResult is stackRevisionErrors.TEMPLATEDIFFERENT
          stackIds.push stack._id
          queue.push (next) ->
            stack.createAdminMessage message, type, next

      queue.push (next) ->
        JGroup = require '../group'
        JGroup.sendStackAdminMessageNotification {
          slug : template.group
          stackIds
          message
          type
        }, next

      async.series queue, (err) -> callback err


  @setGroupStack = (client, options, callback) ->

    { user, group } = client.r
    { templateId, shareCredential = no } = options

    unless templateId
      return callback new KodingError 'Template Id is required'

    if group.getAt('slug') in ['guests', 'koding']
      return callback new KodingError 'Access denied'

    credential    = null
    stackTemplate = null

    async.series [

      # Fetch stacktemplate with requester session
      (next) ->
        JStackTemplate = require './stacktemplate'
        JStackTemplate.one$ client, { _id: templateId }, (err, template) ->
          return next err  if err
          return next new KodingError 'No such template found'  unless template
          stackTemplate = template
          do next

      # Fetch provider credential with requester session
      (next) ->
        stackTemplate.fetchProviderCredential client, (err, _credential) ->
          return next err  if err
          credential = _credential
          do next

      # Set accessLevel of template to 'group'
      (next) ->
        stackTemplate.setAccess client, 'group', next

      # Set template to group
      (next) ->
        group.modify client, {
          stackTemplates: [ stackTemplate.getId() ]
        }, next

      # Share credential with team
      (next) ->
        if shareCredential
          credential.shareWith$ client, { target: group.getAt 'slug' }, next
        else
          do next

      # Notify members about the stack template change
      (next) ->
        group.sendNotification \
          'StackTemplateChanged', stackTemplate.getId(), next

    ], (err) ->
      callback err


  @setGroupStack$ = permit

    advanced: [
      { permission: 'sudoer' }
      { permission: 'sudoer', superadmin: yes }
    ]

    success: revive { shouldReviveProvider: no }, @setGroupStack


  do ->

    JGroup   = require '../group'
    JAccount = require '../account'

    JGroup.on   'MemberAdded',     require './handlers/memberadded'
    JGroup.on   'MemberRemoved',   require './handlers/memberremoved'

    JAccount.on 'UsernameChanged', require './handlers/usernamechanged'
