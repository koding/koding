{ Base, secure, signature } = require 'bongo'

{ argv }     = require 'optimist'
KONFIG       = require('koding-config-manager').load("main.#{argv.c}")

async        = require 'async'
konstraints  = require 'konstraints'

teamutils    = require './teamutils'
KodingError  = require '../../error'
KodingLogger = require '../kodinglogger'

MAX_INT      = Math.pow(2, 32) - 1


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


  @fetchTeamPlans = permit
    advanced : [{ permission: 'sudoer', superadmin: yes }]
    success  : (client, callback) ->
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

    # Create a new JComputeStack based on the template details
    # We will then add machines and other information into it.
    JComputeStack.create {
      title         : template.title
      config        : template.config
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


  # Just takes the plan name and the stack template content generates rules
  # based on th plan then verifies the content based on the rules generated
  @validateTemplateContent = (content, plan) ->

    rules = teamutils.generateConstraints plan

    try
      template = JSON.parse content
    catch
      return new KodingError 'Template is not valid'

    { passed, results } = konstraints template, rules, { log: yes }
    return new KodingError results.last[1]  unless passed

    return null


  # Template checker, this will fetch the stack template from given id,
  # will generate konstraint rules based on the group's plan and finally
  # validate the stack template based on these informations ~ GG
  @validateTemplate = (client, stackTemplateId, group, callback) ->

    plan = group.getAt 'config.plan'

    return callback null  unless plan

    JStackTemplate = require './stacktemplate'
    JStackTemplate.one$ client, { _id: stackTemplateId }, (err, data) =>

      return callback err  if err
      return callback new KodingError 'Stack template not found'  unless data

      callback @validateTemplateContent data.template.content, plan


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


  @updateGroupStackUsage = (group, change, callback) ->

    return callback null  if group.slug is 'koding'

    plan = group.getAt 'config.plan'

    maxAllowed   = MAX_INT
    if plan
      plan       = teamutils.getPlanData plan
      maxAllowed = plan.member

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

    return callback null  if group.slug is 'koding'

    plan = group.getAt 'config.plan'
    return callback null  if amount is 0

    maxAllowed   = MAX_INT
    if plan
      plan       = teamutils.getPlanData plan
      maxAllowed = plan.maxInstance

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
          plan limitations. #{template}
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
          else
            createdStack = stack
            next()

    ], (err) ->
      callback err, createdStack


  do ->

    JGroup   = require '../group'
    JAccount = require '../account'

    JGroup.on   'MemberAdded',     require './handlers/memberadded'
    JGroup.on   'MemberRemoved',   require './handlers/memberremoved'

    JAccount.on 'UsernameChanged', require './handlers/usernamechanged'
