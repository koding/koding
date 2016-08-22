# coffeelint: disable=cyclomatic_complexity
# FIXME ~GG ^^

{ Base, secure, signature } = require 'bongo'

KONFIG       = require 'koding-config-manager'
async        = require 'async'
_            = require 'underscore'
konstraints  = require 'konstraints'

teamutils    = require './teamutils'
KodingError  = require '../../error'
KodingLogger = require '../kodinglogger'

MAX_INT      = Math.pow(2, 32) - 1

helpers      = require './helpers'


module.exports = class ComputeProvider extends Base

  {
    PLANS, PROVIDERS, fetchGroupStackTemplate, revive,
    fetchUsage, checkTemplateUsage
  } = require './computeutils'

  @trait __dirname, '../../traits/protected'

  { permit } = require '../group/permissionset'

  JMachine       = require './machine'
  JWorkspace     = require '../workspace'

  @COUNTER_TYPE  =
    stacks       : 'member_stacks'
    instances    : 'member_instances'

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
        fetchUsage        :
          (signature Object, Function)
        fetchPlans        :
          (signature Function)
        fetchTeamPlans    :
          (signature Function)
        fetchProviders    :
          (signature Function)
        createGroupStack  :
          (signature Function)
        fetchSoloMachines :
          (signature Function)


  @providers      = PROVIDERS


  @fetchProviders = secure (client, callback) ->
    callback null, Object.keys PROVIDERS


  @ping = (client, options, callback) ->

    { provider } = options
    provider.ping client, options, callback


  @ping$ = permit 'ping machines',
    success: revive {
      shouldReviveClient   : yes
      shouldPassCredential : yes
    }, @ping


  @create = revive

    shouldReviveClient       : yes
    shouldReviveProvisioners : yes
    shouldFetchGroupPlan     : yes

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
    shouldFetchGroupPlan : yes

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


  @fetchUsage$ = secure (client, options, callback) ->
    ComputeProvider.fetchUsage client, options, callback

  @fetchUsage = revive

    shouldReviveClient   : yes
    shouldPassCredential : yes

  , (client, options, callback) ->

    { slug } = options.provider
    fetchUsage client, { provider: slug }, callback


  @fetchPlans = permit 'create machines',
    success: (client, callback) ->
      callback null, PLANS


  @fetchTeamPlans = permit 'create machines',
    success: (client, callback) ->
      callback null, teamutils.TEAMPLANS


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

              return next()  unless machine

              # Create default workspace for the machine
              JWorkspace.createDefault client, machine.uid, (err) ->

                if err
                  console.log \
                    'Failed to create default workspace', machine.uid, err

                next()

          # This is optional, since for koding group for example
          # we don't want to add our admins into users machines ~ GG
          unless options.addGroupAdminToMachines
            return create machineInfo

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
                create machineInfo
            else
              create machineInfo


      async.series queue, -> callback null, { stack, results }


  # Just takes the plan config and the stack template content generates rules
  # based on th plan then verifies the content based on the rules generated
  @validateTemplateContent = (content, planConfig, callback) ->

    try
      template = JSON.parse content
    catch
      return callback new KodingError 'Template is not valid'

    teamutils.fetchConstraints planConfig, (err, rules) ->

      { passed, results } = konstraints template, rules, {}
      return callback new KodingError results.last[1]  unless passed

      return callback null


  # Template checker, this will fetch the stack template from given id,
  # will generate konstraint rules based on the group's plan and finally
  # validate the stack template based on these informations ~ GG
  @validateTemplate = (client, stackTemplateId, group, callback) ->

    planConfig = helpers.getPlanConfig group

    return callback null  unless planConfig.plan

    JStackTemplate = require './stacktemplate'
    JStackTemplate.one$ client, { _id: stackTemplateId }, (err, data) =>

      return callback err  if err
      return callback new KodingError 'Stack template not found'  unless data

      @validateTemplateContent data.template.content, planConfig, callback


  # Takes an array of stack template ids and returns the final result ^^
  @validateTemplates = (client, stackTemplates, group, callback) ->

    queue = []

    stackTemplates.forEach (stackTemplateId) -> queue.push (next) ->
      ComputeProvider.validateTemplate client, stackTemplateId, group, (err) ->
        return callback err  if err
        next()

    async.series queue, -> callback null


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


  @fetchGroupResources = (group, selector, options, callback) ->

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
              reviveQueue.push (next) -> stack.revive next
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
    # we need to check plan limits for the current group and create the stack
    # and related machines here, this is very critical for multiple stacks ~ GG

    async.series [

      (next) ->
        fetchGroupStackTemplate client, (err, _res) ->
          unless err
            { template, account, group } = res = _res
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
            account.removeStackTemplate template, -> next err
          else
            createdStack = stack
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


  @fetchSoloMachines = secure revive

    shouldReviveProvider : no
    shouldReviveClient   : yes
    hasOptions           : no

  , (client, callback) ->

    { user, group, account } = client.r

    { isSoloAccessible } = require '../user/validators'

    return callback null, { machines: [] }  unless isSoloAccessible {
      groupName: 'koding'
      account: account
      env: KONFIG.environment
    }

    activeMachinesSelector = {
      'users.id': user.getId()
      'provider': 'koding'
      'status.state': {
        $in: [
          'Starting', 'Running',
          'Stopped', 'Stopping', 'Rebooting'
        ]
      }
    }

    JMachine.some activeMachinesSelector, { limit: 30 }, (err, machines) ->

      if err or not machines?.length
        return callback null, { machines: [] }

      callback null, { machines }


  do ->

    JGroup   = require '../group'
    JAccount = require '../account'

    JGroup.on   'MemberAdded',     require './handlers/memberadded'
    JGroup.on   'MemberRemoved',   require './handlers/memberremoved'

    JAccount.on 'UsernameChanged', require './handlers/usernamechanged'
