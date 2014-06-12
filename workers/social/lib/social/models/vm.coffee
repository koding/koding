{Model} = require 'bongo'
{Relationship, Module} = require 'jraphical'
{argv} = require 'optimist'
KONFIG = require('koding-config-manager').load("main.#{argv.c}")

JPaymentPack = require "./payment/pack"

module.exports = class JVM extends Module

  {permit} = require './group/permissionset'
  {ObjectId, secure, dash, signature} = require 'bongo'
  {uniq}   = require 'underscore'

  {argv} = require 'optimist'

  KodingError = require '../error'

  JPaymentSubscription = require './payment/subscription'
  JPaymentPack         = require './payment/pack'
  JPermissionSet       = require './group/permissionset'
  JDomain              = require './domain'

  @share()

  @trait __dirname, '../traits/protected'

  @bound = require 'koding-bound'

  handleError = (err)-> console.error err  if err

  VMDefaultDiskSize = @VMDefaultDiskSize = 3072
  @set
    softDelete          : yes
    indexes             :
      hostnameAlias     : 'unique'
    permissions         :
      'sudoer'          : []
      'create vms'      : ['member','moderator']
      'delete vms'      : ['member','moderator']
      'update vms'      : ['member','moderator']
    sharedEvents        :
      static            : [
        { name : "RemovedFromCollection" }
      ]
      instance          : [
        { name : "RemovedFromCollection" }
        { name : "control" }
      ]
    sharedMethods       :

      static            :
        fetchVms: [
          (signature Function)
          (signature Object, Function)
        ]
        fetchVmsByContext: [
          (signature Function)
          (signature Object, Function)
        ]
        fetchVmsByName: [
          (signature Object, Function)
        ]
        fetchVmInfo:
          (signature String, Function)
        fetchDomains:
          (signature String, Function)
        removeByHostname:
          (signature String, Function)
        someData:
          (signature Object, Object, Object, Function)
        count:
          (signature Object, Function)
        fetchDefaultVm:
          (signature Function)
        resetDefaultVMLimits:
          (signature Function)
        fetchVmRegion:
          (signature String, Function)
        createVmByNonce:
          (signature String, String, Function)
        createSharedVm:
          (signature Function)
        setAlwaysOn:
          (signature Object, Function)
        updateInitScript:
          (signature String, String, Function)

    schema              :
      ip                :
        type            : String
        default         : -> null
      ldapPassword      :
        type            : String
        default         : -> null
      hostnameAlias     :
        type            : String
        required        : yes
      hostKite          :
        type            : String
        default         : -> null
      region            :
        type            : String
        enum            : ['unknown region'
                          [
                            'aws' # Amazon Web Services
                            'sj'  # San Jose
                            'vagrant'
                            'premium-sj'
                          ]]
        default         : if argv.c is 'vagrant' then 'vagrant' else 'sj'
      webHome           : String
      planCode          : String
      subscriptionCode  : String
      disableSecurePage : Boolean
      vmType            :
        type            : String
        default         : 'user'
      users             : Array
      groups            : Array
      isEnabled         :
        type            : Boolean
        default         : yes
      shouldDelete      :
        type            : Boolean
        default         : no
      pinnedToHost      : String
      alwaysOn          :
        type            : Boolean
        default         : no
      maxMemoryInMB     :
        type            : Number
        default         : KONFIG.defaultVMConfigs.freeVM.ram ? 1024
      diskSizeInMB      :
        type            : Number
        default         : KONFIG.defaultVMConfigs.freeVM.storage ? VMDefaultDiskSize
      numCPUs           :
        type            : Number
        default         : KONFIG.defaultVMConfigs.freeVM.cpu ? 1
      stack             : ObjectId
      meta              : Object
      state             :
        type            : String
        enum            : ['unknown state', ['RUNNING','STOPPED','FAILED']]
        default         : 'STOPPED'

  @updateInitScript = secure (client, hostnameAlias, script, callback) ->
    {delegate} = client.connection
    {group}    = client.context
    user       = delegate.profile.nickname

    delegate.fetchUser (err, user) ->
      return callback err  if err
      return callback new Error "user not found" unless user

      JVM.one
        hostnameAlias : hostnameAlias
        users         : { $elemMatch: id: user.getId() }
      , (err, vm) ->
        return callback err  if err
        return callback null, null  unless vm
        vm.update $set: "meta.initScript": script, (err) =>
          err = new KodingError {message: "Failed to update", err}  if err

          callback err, vm


  suspend: (callback)->
    @update { $set: { hostKite: '(banned)' } }, (err)=>
      return callback err if err
      @emit 'control', {
        routingKey: "control.suspendVM"
        @hostnameAlias
      }
      return callback null

  @setAlwaysOn = secure (client, options, callback)->
    {connection: {delegate}, context: {group}} = client
    {vmName, status} = options

    fetchVmByHostname delegate, vmName, (err, vm) ->
      return callback err if err

      kallback = (subscription) ->
        JPaymentPack.one tags: "alwayson", (err, pack) ->
          return callback err  if err
          return callback new KodingError "Always On pack not found"  unless pack
          {debit, credit} = subscription
          fn = if status then debit else credit
          fn.call subscription, {pack}, (err) ->
            return callback err  if err
            vm.update $set: alwaysOn: status, callback

      if group is "koding"
        options = targetOptions: tags: $in: "vm"
        delegate.fetchSubscriptions null, options, (err, subscriptions) ->
          noSyncSubscription = null
          activeSubscription = null

          for subscription in subscriptions
            if "nosync" in subscription.tags
              noSyncSubscription = subscription
            else
              activeSubscription = subscription

          subscription = activeSubscription or noSyncSubscription
          if subscription
          then kallback subscription
          else callback message: "Subscription not found", code: "no subscription"
      else
        JGroup = require './group'
        JGroup.one slug: group, (err, group) ->
          return callback err  if err
          group.fetchSubscription (err, subscription) ->
            return callback err  if err
            kallback subscription

  @fetchDefaultVm_ = (client, callback)->
    {delegate} = client.connection
    delegate.fetchUser (err, user) ->
      return callback err  if err
      return callback new Error "User not found" unless user

      JGroup = require './group'
      JGroup.one slug:'koding', (err, fetchedGroup)=>
        return callback err  if err
        JVM.one
          users    : { $elemMatch: id: user.getId() }
          groups   : { $elemMatch: id: fetchedGroup.getId() }
          planCode : 'free'
        , callback


  @resetDefaultVMLimits = secure (client, callback)->
    @fetchDefaultVm_ client, (err, vm)->
      return callback err  if err
      return callback new Error "VM not found" unless vm
      vm.update {$set: diskSizeInMB: VMDefaultDiskSize}, (err) ->
        return callback err if err
        callback null, vm.hostnameAlias

  @createAliases = ({nickname, type, uid, groupSlug})->
    domain       = 'kd.io'
    aliases      = []
    type        ?= 'user'

    if type in ['user', 'expensed']
      if uid is 0
        aliases.push "#{nickname}.#{groupSlug}.#{domain}"
      if groupSlug in ['koding', 'guests']
        aliases.push "#{nickname}.#{domain}"  if uid is 0
        aliases.push "vm-#{uid}.#{nickname}.#{domain}"
      aliases.push "vm-#{uid}.#{nickname}.#{groupSlug}.#{domain}"

    else if type is 'group'
      if uid is 0
        aliases = ["#{groupSlug}.#{domain}"
                   "shared.#{groupSlug}.#{domain}"
                   "shared-0.#{groupSlug}.#{domain}"]
      else
        aliases = ["shared-#{uid}.#{groupSlug}.#{domain}"]

    return aliases.reverse()

  @parseAlias = (alias)->
    # group-vm alias
    if /^shared\-[0-9]+/.test alias
      result = alias.match /(.*)\.([a-z0-9\-]+)\.kd\.io$/
      if result
        [rest..., prefix, groupSlug] = result
        uid = parseInt(prefix.split(/-/)[1], 10)
        return {groupSlug, prefix, uid, type:'group', alias}
    # personal-vm alias
    else if /^vm\-[0-9]+/.test alias
      result = alias.match /(.*)\.([a-z0-9\-]+)\.([a-z0-9\-]+)\.kd\.io$/
      if result
        [rest..., prefix, nickname, groupSlug] = result
        uid = parseInt(prefix.split(/-/)[1], 10)
        return {groupSlug, prefix, nickname, uid, type:'user', alias}
    return null


  @createVmByNonce = secure (client, nonce, stackId, callback) ->
    JPaymentFulfillmentNonce  = require './payment/nonce'
    JPaymentPack              = require './payment/pack'

    JPaymentFulfillmentNonce.one { nonce }, (err, nonceObject) =>
      return callback err  if err
      return callback { message: "Unrecognized nonce!", nonce }  unless nonceObject
      return callback { message: "Invalid nonce!", nonce }  if nonceObject.action isnt "debit"

      { planCode, subscriptionCode } = nonceObject
      { delegate: account } = client.connection
      { group: groupSlug } = client.context
      type = "user"

      nonceObject.update $set: action: "used", (err) =>
        return callback err  if err
        @createVm {
          account
          groupSlug
          planCode
          subscriptionCode
          stackId
          type
        }, callback

  @createSharedVm = secure (client, callback)->
    {connection:{delegate:account}, context:{group}} = client
    JGroup = require './group'
    JGroup.one {slug:group}, (err, group)=>
      return callback err  if err
      group.fetchAdmins (err, admins)=>
        return callback err  if err

        adminIds = admins.map (admin) ->
          admin.getId().toString()

        return callback new Error "You can not create shared VM" unless account.getId().toString() in adminIds

        group.fetchSubscription (err, subscription) =>
          return callback err  if err or not subscription

          subscription.debitPack tag: "vm", (err) =>
            return callback err  if err
            @createVm {
              type      : "group"
              groupSlug : group.slug
              account
            }, callback

  # TODO: this needs to be rethought in terms of bundles, as per the
  # discussion between Devrim, Chris T. and Badahir  C.T.
  @createVm = ({account, type, groupSlug, planCode, stackId, subscriptionCode}, callback)->
    JGroup = require './group'
    JStack = require './stack'
    JGroup.one {slug: groupSlug}, (err, group)=>
      return callback err  if err
      return callback new Error "Group not found"  unless group

      account.fetchUser (err, user)=>
        return callback err  if err
        return callback new Error "user is not defined"  unless user

        # We are keeping this names just for counter
        {nickname} = account.profile
        webHome    = if type is "group" then groupSlug else nickname

        counterName = "#{groupSlug}~#{nickname}~"
        nameFactory = (require 'koding-counter') {
          db     : JVM.getClient()
          offset : 0
          counterName
        }

        nameFactory.next (err, uid)=>
          return callback err  if err

          hostnameAliases = JVM.createAliases {
            nickname, type, uid, groupSlug
          }
          users         = [{ id: user.getId(), sudo: yes, owner: yes }]
          groups        = [{ id: group.getId() }]
          hostnameAlias = hostnameAliases[0]

          vm = new JVM {
            hostnameAlias
            planCode
            subscriptionCode
            webHome
            groups
            users
            vmType : type
            stack  : stackId
          }

          JPaymentSubscription.isFreeSubscripton subscriptionCode, (err, isFreeSubscripton)=>
            return callback err if err

            vm.region = KONFIG.regions.premium unless isFreeSubscripton

            vm.save (err) =>

              if err
                return console.error "Failed to create VM for ", \
                                     {users, groups, hostnameAlias, err}

              JDomain.createDomains {
                account, stackId,
                domains: hostnameAliases
                hostnameAlias: hostnameAliases[0]
                group: groupSlug
              }

              group.addVm vm, (err)=>
                return callback err  if err
                JDomain.ensureDomainSettingsForVM {
                  account, vm, type, nickname, group: groupSlug, stackId
                }
                account.sendNotification "VMCreated"
                if type is 'group'
                  @addVmUsers user, vm, group, ->
                    callback null, vm
                else
                  callback null, vm

  @addVmUsers = (user, vm, group, callback)->
    # todo - do this operation in batches
    selector =
      sourceId    : group.getId()
      sourceName  : "JGroup"
      as          : "member"

    # fetch members of the group
    Relationship.someData selector, {targetId:1}, (err, cursor)->
      return callback err  if err

      cursor.toArray (err, targetIds)->
        return callback err  if err
        targetIds or= []

        # aggregate them into accountIds
        accountIds = targetIds.map (rec)-> rec.targetId

        selector =
          targetId   : {$in : accountIds}
          targetName : "JAccount"
          as         : 'owner'
          sourceName : 'JUser'

        # fetch userids of the accounts
        Relationship.someData selector, {sourceId:1}, (err, cursor)->
          return callback err  if err

          cursor.toArray (err, sourceIds)->
            return callback err  if err
            sourceIds or= []
            vmUsers = []

            vmUsers = sourceIds.map (rec)->
              owner = if rec.sourceId.equals user.getId() then yes else no
              { id: rec.sourceId, sudo: yes, owner }

            return vm.update {
              $set: users: vmUsers
            }, callback

  @fetchVmInfo = secure (client, hostnameAlias, callback)->
    {delegate} = client.connection

    delegate.fetchUser (err, user) ->
      return callback err  if err
      return callback new Error "user not found" unless user

      JVM.one
        hostnameAlias : hostnameAlias
        users         : { $elemMatch: id: user.getId() }
      , (err, vm)->
        return callback err  if err
        return callback null, null  unless vm
        callback null,
          planCode         : vm.planCode
          hostnameAlias    : vm.hostnameAlias
          underMaintenance : vm.hostKite is "(maintenance)"
          region           : vm.region or 'sj'
          diskSizeInMB     : vm.diskSizeInMB
          alwaysOn         : vm.alwaysOn
          groupId          : vm.groups[0].id

  @fetchVmRegion = secure (client, hostnameAlias, callback)->
    {delegate} = client.connection
    JVM.one {hostnameAlias}, (err, vm)->
      return callback err  if err or not vm
      callback null, vm.region

  @fetchDefaultVm = secure (client, callback)->
    @fetchDefaultVm_ client, (err, vm)->
      return callback err  if err
      callback null, vm?.hostnameAlias

  @fetchAccountVmsBySelector = (account, selector, options, callback) ->
    [callback, options] = [options, callback]  unless callback

    options ?= {}
    # options.limit = Math.min options.limit ? 10, 10

    account.fetchUser (err, user) ->
      return callback err  if err
      return callback new Error "user not found" unless user

      selector.users = $elemMatch: id: user.getId()

      fieldsToFetch = { hostnameAlias: 1, region: 1, hostKite: 1, stack: 1, alwaysOn: 1, groups: 1, meta: 1 }
      JVM.someData selector, fieldsToFetch, options, (err, cursor)->
        return callback err  if err
        cursor.toArray (err, arr) ->
          return callback err  if err
          callback null, arr.map (vm) ->
            { hostnameAlias, region, hostKite, stack, alwaysOn, groups, meta } = vm
            hostKite = null  if hostKite in ['(banned)', '(maintenance)']
            {
              hostnameAlias
              region
              hostKite
              stack
              alwaysOn
              meta
              groupId: groups[0].id
            }

  @fetchVmsByContext = secure (client, options, callback) ->
    {connection:{delegate}, context:{group}} = client
    JGroup = require './group'

    slug = group ? if delegate.type is 'unregistered' then 'guests' else 'koding'

    JGroup.one {slug}, (err, fetchedGroup) =>
      return callback err  if err

      selector = groups: { $elemMatch: id: fetchedGroup.getId() }
      @fetchAccountVmsBySelector delegate, selector, options, callback

  @fetchVms = secure (client, options, callback) ->
    {delegate} = client.connection
    @fetchAccountVmsBySelector delegate, {}, options, callback

  @fetchVmsByName = secure (client, names, callback) ->
    { delegate } = client.connection
    @fetchAccountVmsBySelector delegate, { hostnameAlias: $in: names }, callback

  # TODO: Move these methods to JDomain at some point ~ GG
  # ------------------------------------------------------
  # Private static method to fetch domains
  @fetchDomains = (selector, callback)->
    JDomain = require './domain'
    JDomain.someData selector, {domain:1}, \
    (err, cursor)->
      return callback err, []  if err
      cursor.toArray (err, arr)->
        return callback err, []  if err
        callback null, arr.map (vm)-> vm.domain

  # Public(shared) static method to fetch domains
  # which points to given hostnameAlias
  @fetchDomains$ = secure (client, hostnameAlias, callback)->
    {delegate} = client.connection

    delegate.fetchUser (err, user) ->
      return callback err  if err
      return callback new Error "user not found" unless user

      selector =
        hostnameAlias : hostnameAlias
        users         : { $elemMatch: id: user.getId() }

      JVM.one selector, {hostnameAlias:1}, (err, vm)->
        return callback err, []  if err or not vm
        JVM.fetchDomains {hostnameAlias: vm.hostnameAlias}, callback

  @removeRelatedDomains = (vm, callback=->)->
    vmInfo = @parseAlias vm.hostnameAlias
    return callback null  unless vmInfo

    # Create same aliases based on vm info
    aliasesToDelete = @createAliases vmInfo

    # If calculated uid is greater than 0 we also try to add
    # aliases which has uid 0
    if vmInfo.uid > 0
      vmInfo.uid = 0
      aliasesToDelete = uniq aliasesToDelete.concat @createAliases vmInfo

    selector =
      hostnameAlias : vm.hostnameAlias
      domain        : { $in : aliasesToDelete }

    JDomain = require './domain'
    JDomain.remove selector, (err)->
      callback err
      return console.error "Failed to delete domains:", err  if err

  remove: (callback)->
    JVM.removeRelatedDomains this
    super callback

  removeFromSubscription: (account, group, callback)->
    kallback = (subscription) =>
      @remove (err) =>
        return callback err  if err

        account.sendNotification "VMRemoved"

        errs = []

        dash queue = [
          ->
            subscription.creditPack tag: "vm", (err) ->
              if err
                console.error "VM credit error: ",  err
                errs.push new KodingError "VM usage couldn't be credited"
                console.warn "VM cannot be credited to user #{account.profile.nickname}: #{err}"
              queue.fin()
        ,
          =>
            return queue.fin()  unless @alwaysOn
            subscription.creditPack tag: "alwayson", (err) ->
              if err
                console.error "Always on credit error: ", err
                errs.push new KodingError "Always On usage couldn't be credited"
                console.warn "Always On pack couldn't be credited to user #{account.profile.nickname}: #{err}"
              queue.fin()
        ], ->
          if errs.length
          then callback errs
          else callback()

    if group.slug is "koding"
      options = targetOptions: tags: $in: "vm"
      account.fetchSubscriptions null, options, (err, subscriptions = []) =>
        return callback err  if err

        subscription = freeSubscription = null
        for item in subscriptions
          if "nosync" in item.tags
            freeSubscription = item
          else
            subscription = item

        kallback subscription or freeSubscription
    else
      group.fetchSubscription (err, subscription) =>
        return callback err  if err
        return callback new KodingError "Group subscription not found"  unless subscription
        kallback subscription

  @removeByHostname = secure (client, hostnameAlias, callback)->
    {delegate} = client.connection

    fetchVmByHostname delegate, hostnameAlias, (err, vm) ->
      return callback err  if err
      [{ id: groupId }] = vm.groups
      JGroup = require './group'
      JGroup.one { _id: groupId }, (err, group)->
        return callback err  if err
        return callback new KodingError "Group not found"  unless group
        JPermissionSet.checkPermission client, "delete vms", group, (err, hasPermission)->
          return callback err  if err
          return callback new KodingError "You do not have permission to delete this vm"  unless hasPermission
          vm.removeFromSubscription delegate, group, callback

  fetchVmByHostname = (account, hostnameAlias, callback) ->
    account.fetchUser (err, user) =>
      return callback err  if err
      return callback new KodingError "user not found"  unless user

      selector =
        hostnameAlias : hostnameAlias
        users         : { $elemMatch: id: user.getId() }

      JVM.one selector, (err, vm) ->
        return callback err  if err
        return callback new KodingError "VM not found"  unless vm

        isOwner = vm.users.filter (vmUser) ->
          vmUser.id.equals(user.getId()) && vmUser.owner is true

        err = new KodingError("You are not owner of this VM", "NOTPERMITTED")  unless isOwner.length
        callback err, vm

  @addVm = ({ account, target, user, sudo, groups, groupSlug
             type, planCode, planOwner, webHome, uid, stack }, callback)->

    return handleError new Error "user is not defined"  unless user
    nickname = account.profile.nickname or user.username
    uid ?= 0
    hostnameAliases = JVM.createAliases {
      nickname
      type, uid, groupSlug
    }

    users = [
      { id: user.getId(), sudo: yes, owner: yes }
    ]

    [hostnameAlias]  = hostnameAliases
    groups          ?= []

    vm = new JVM {
      hostnameAlias
      planOwner
      planCode
      webHome
      groups
      users
      vmType: type
      stack
    }

    vm.save (err)->

      callback? err, vm  unless err

      handleError err

      if err
        return console.error "Failed to create VM for ", {
          users, groups, hostnameAlias, err
        }

      group = groupSlug

      JDomain.ensureDomainSettingsForVM {
        account, vm, type, nickname, group, stack
      }

      JDomain.createDomains {
        account, domains:hostnameAliases,
        group, hostnameAlias, stack
      }

      target.addVm vm, handleError

  wrapGroup = (group)-> [ { id: group.getId() } ]

  do ->

    JAccount  = require './account'
    JGroup    = require './group'
    JUser     = require './user'

    uidFactory = null

    require('bongo').Model.on 'dbClientReady', ->
      uidFactory = (require 'koding-counter') {
        db          : JVM.getClient()
        counterName : 'uid'
        offset      : 1e6
      }
      uidFactory.initialize()

    JUser.on 'UserCreated', (user)->
      uidFactory.next (err, uid)->
        if err then handleError err
        else user.update { $set: { uid } }, handleError

    JUser.on "UserBlocked", (user)->
      return handleError new Error "user not found" unless user
      selector =
        'users.id'    : user.getId()
        'users.owner' : yes

      JVM.some selector, {}, (err, vms)->
        return console.error err  if err
        queue = vms.map (vm)->->
          # shutdown all vms that user has
          vm.suspend -> queue.fin()
        if queue.length > 0
          dash queue, (err)->
            console.error err if err

    JUser.on "UserUnblocked", (user)->
      return handleError new Error "user not found" unless user
      selector =
        'users.id'    : user.getId()
        'users.owner' : yes

      JVM.some selector, {}, (err, vms)->
        return console.error err  if err
        queue = vms.map (vm)->->
          vm.update { $set: { hostKite: null } }, -> queue.fin()
        if queue.length > 0
          dash queue, (err)->
            console.error err if err

    JAccount.on 'UsernameChanged', ({ oldUsername, username, isRegistration })->
      return  unless oldUsername and username

      if isRegistration
        oldGroup  = 'guests'
        group     = 'koding'
      else
        oldGroup = group = 'koding'

      hostnameAlias = "vm-0.#{oldUsername}.#{oldGroup}.kd.io"
      newHostNameAlias = "vm-0.#{username}.#{group}.kd.io"

      console.log "Started to migrate #{oldUsername} to #{username} ..."

      JVM.one {hostnameAlias}, (err, vm)=>
        return console.error err  if err or not vm
        # Old vm found

        # Removing old vm domains...
        JVM.removeRelatedDomains vm, (err)=>
          if err
            console.error "Failed to remove old domains for #{hostnameAlias}", err

          JAccount.one {'profile.nickname':username}, (err, account)=>
            return console.error err  if err or not account
            # New account found
            webHome       = username

            JStack = require './stack'
            JStack.getStackId {user:username, group}, (err, stack)=>

              if err then warn "Failed to get stack:", err

              stack ?= null
              vm.update
                $set: {
                  webHome, stack,
                  hostnameAlias: newHostNameAlias
                }
              , (err)=>

                return console.error err  if err
                # VM hostnameAlias updated

                nameFactory = (require 'koding-counter')
                  db          : JVM.getClient()
                  offset      : 0
                  counterName : "koding~#{username}~"

                nameFactory.next (err, uid)=>
                  return console.error err  if err
                  # Counter created

                  hostnameAliases = JVM.createAliases {
                    nickname:username, uid,
                    type:'user', groupSlug:group
                  }

                  JDomain.createDomains {
                    account, stack, group,
                    domains:hostnameAliases,
                    hostnameAlias:hostnameAliases[0]
                  }

                  console.log """Migration completed for
                                 #{hostnameAlias} to #{newHostNameAlias}"""

    JGroup.on 'GroupDestroyed', (group)->
      group.fetchVms (err, vms)->
        if err then handleError err
        else vms.forEach (vm)-> vm.remove handleError

    JGroup.on 'MemberAdded', ({group, member})->
      member.fetchUser (err, user)->
        return handleError err  if err
        return handleError new Error "user not defined" unless user

        if group.slug is 'guests'
          # Following is just here to register this name in the counters collection
          ((require 'koding-counter') {
            db          : JVM.getClient()
            counterName : "koding~#{member.profile.nickname}~"
            offset      : 0
          }).next ->

          # TODO: this special case for koding should be generalized for any group.
          JVM.addVm {
            user
            account   : member
            sudo      : yes
            type      : 'user'
            target    : member
            planCode  : 'free'
            planOwner : "user_#{member._id}"
            groupSlug : group.slug
            webHome   : member.profile.nickname
            groups    : wrapGroup group
          }
        else if group.slug is 'koding'
          member.fetchVms (err, vms)->
            if err then handleError err
            else
              vms.forEach (vm) ->
                vm.update $set: groups: [id: group.getId()], handleError
        else
          member.checkPermission group, 'sudoer', (err, hasPermission)->
            if err then handleError err
            else
              group.fetchVms (err, vms)->
                if err then handleError err
                else vms.forEach (vm)->
                  if vm.vmType is 'group'
                    vm.update {
                      $addToSet: users: { id: user.getId(), sudo: hasPermission }
                    }, handleError

    JGroup.on 'MemberRemoved', ({group, member})->
      member.fetchUser (err, user)->
        return handleError err  if err
        return handleError new Error "user not found" unless user

        # Do we need to take care guests here? Like when guests ends up session
        # Do we also need to remove their vms? ~ GG
        if group.slug is 'koding'
          member.fetchVms (err, vms)->
            if err then handleError err
            else vms.forEach (vm)->
              vm.update {
                $set: { isEnabled: no, shouldDelete: yes }
              }, handleError
        else
          # group.fetchVms (err, vms)->
          #   if err then handleError err
          #   else vms.forEach (vm)->
          #     JVM.update {_id: vm.getId()}, { $pull: id: user.getId() }, handleError
          # TODO: the below is more efficient and a little less strictly correct than the above:
          JVM.update { groups: group.getId() }, { $pull: id: user.getId() }, handleError

    JGroup.on 'MemberRolesChanged', ({group, member})->
      return  if group.slug 'koding'  # TODO: remove this special case
      member.fetchUser (err, user)->
        return handleError err  if err
        return handleError new Error "user not found"  unless user

        member.checkPermission group, 'sudoer', (err, hasPermission)->
          if err then handleError err
          else if hasPermission
            member.fetchVms (err, vms)->
              if err then handleError err
              else
                vms.forEach (vm)->
                  vm.update {
                    $set: users: vm.users.map (userRecord)->
                      isMatch = userRecord.id.equals user.getId()
                      return userRecord  unless isMatch
                      return { id, sudo: hasPermission }
                  }, handleError
