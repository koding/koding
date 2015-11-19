{ Base, secure, signature, daisy } = require 'bongo'
KodingError = require '../../error'

{ argv }    = require 'optimist'
KONFIG      = require('koding-config-manager').load("main.#{argv.c}")
teamutils   = require './teamutils'
konstraints = require 'konstraints'


module.exports = class ComputeProvider extends Base

  {
    PLANS, PROVIDERS, fetchGroupStackTemplate, revive,
    fetchUsage, checkTemplateUsage
  } = require './computeutils'

  @trait __dirname, '../../traits/protected'

  { permit } = require '../group/permissionset'

  JMachine       = require './machine'
  JWorkspace     = require '../workspace'
  JStackTemplate = require './stacktemplate'

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

    { r: { account } } = client
    { stack } = options

    JComputeStack = require '../stack'
    JComputeStack.getStack account, stack, (err, revivedStack) =>
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

        queue.push ->

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

              return queue.next()  unless machine

              # Create default workspace for the machine
              JWorkspace.createDefault client, machine.uid, (err) ->

                if err
                  console.log \
                    'Failed to create default workspace', machine.uid, err

                queue.next()

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

      queue.push ->

        callback null, { stack, results }

      daisy queue


  # Template checker, this will fetch the stack template from given id,
  # will generate konstraint rules based on the group's plan and finally
  # validate the stack template based on these informations ~ GG
  @validateTemplate = (client, stackTemplateId, group, callback) ->

    plan = group.getAt 'config.plan'
    return callback null  unless plan

    rules = teamutils.generateConstraints plan

    JStackTemplate.one$ client, { _id: stackTemplateId }, (err, data) ->

      return callback err  if err
      return callback new KodingError 'Stack template not found'  unless data

      try
        template = JSON.parse data.template.content
      catch
        return callback new KodingError 'Template is not valid'

      { passed, results } = konstraints template, rules, { log: yes }
      return callback new KodingError results.last[1]  unless passed

      callback null


  # Takes an array of stack template ids and returns the final result ^^
  @validateTemplates = (client, stackTemplates, group, callback) ->

    queue = []

    stackTemplates.forEach (stackTemplateId) -> queue.push ->
      ComputeProvider.validateTemplate client, stackTemplateId, group, (err) ->
        return callback err  if err
        queue.next()

    queue.push -> callback null

    daisy queue


  # Auto create stack operations ###

  @createGroupStack$ = permit 'create machines',

    success: (client, callback) ->

      ComputeProvider.createGroupStack client, callback


  @createGroupStack = (client, options, callback) ->

    [options, callback] = [callback, options]  unless callback
    callback ?= ->
    options  ?= {}

    fetchGroupStackTemplate client, (err, res) ->

      return callback err  if err

      { template, account } = res
      checkTemplateUsage template, account, (err) ->
        return callback err  if err

        account.addStackTemplate template, (err) ->
          return callback err  if err

          res.client = client
          ComputeProvider.generateStackFromTemplate res, options, callback


  do ->

    JGroup   = require '../group'
    JAccount = require '../account'

    JGroup.on   'MemberAdded',     require './handlers/memberadded'
    JGroup.on   'MemberRemoved',   require './handlers/memberremoved'

    JAccount.on 'UsernameChanged', require './handlers/usernamechanged'
