{Model} = require 'bongo'

module.exports = class JVM extends Model

  {permit} = require './group/permissionset'
  {secure} = require 'bongo'

  KodingError = require '../error'

  JRecurlySubscription = require './recurly/subscription'
  JPermissionSet       = require './group/permissionset'

  @share()

  @trait __dirname, '../traits/protected'

  @bound = require 'koding-bound'

  @set
    softDelete          : yes
    permissions         :
      'sudoer'          : []
      'create vms'      : ['member','moderator']
      'delete vms'      : ['member','moderator']
      'list all vms'    : ['member','moderator']
      'list default vm' : ['member','moderator']
    sharedMethods       :
      static            : [
                           'fetchVms','fetchVmsByContext'#,'calculateUsage'
                           'removeByHostname', 'someData'#, 'fetchDomains'
                           'fetchVMInfo', 'count'
                          ]
      instance          : []
    schema              :
      ip                :
        type            : String
        default         : -> null
      ldapPassword      :
        type            : String
        default         : -> null
      hostname          : String
      webHome           : String
      planOwner         : String
      planCode          : String
      users             : Array
      groups            : Array
      usage             : # TODO: usage seems like the wrong term for this.
        cpu             :
          type          : Number
          default       : 1
        ram             :
          type          : Number
          default       : 0.25
        disk            :
          type          : Number
          default       : 0.5
      isEnabled         :
        type            : Boolean
        default         : yes
      shouldDelete      :
        type            : Boolean
        default         : no

  @createDomains = (domains) ->
    JDomain = require './domain'
    domains.forEach (domain) ->
      (new JDomain
        domain        : domain
        hostnameAlias : [domains[0]]
        proxy         : { mode: 'vm' }
        regYears      : 0
      ).save (err)-> console.log err  if err?

  @createAliases = ({nickname, type, uid, groupSlug})->
    domain       = 'kd.io'
    aliases      = []

    if type is 'user'
      if uid is 0
        aliases.push "#{nickname}.#{groupSlug}.#{domain}"
      if groupSlug is 'koding'
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

  # TODO: this needs to be rethought in terms of bundles, as per the
  # discussion between Devrim, Chris T. and Badahir  C.T.
  @createVm = ({account, type, groupSlug, usage, planCode}, callback)->
    JGroup = require './group'
    JGroup.one {slug: groupSlug}, (err, group)=>
      return callback err  if err
      account.fetchUser (err, user)=>
        return callback err  if err

        # We are keeping this names just for counter
        planOwner   = "group_#{group._id}"
        counterName = "#{groupSlug}~"
        webHome     = groupSlug

        if type is 'user'
          planOwner   = "user_#{account._id}"
          counterName = "#{groupSlug}~#{user.username}~"
          webHome     = user.username

        nameFactory = (require 'koding-counter') {
          db     : JVM.getClient()
          offset : 0
          counterName
        }

        nameFactory.next (err, uid)=>
          return callback err  if err

          hostnameAliases = JVM.createAliases {
            nickname : user.username
            type, uid, groupSlug
          }

          JVM.createDomains hostnameAliases

          vm = new JVM {
            planCode      : planCode
            planOwner     : planOwner
            users         : [{ id: user.getId(), sudo: yes, owner: yes }]
            groups        : [{ id: group.getId() }]
            hostname      : hostnameAliases[0]
            webHome
            usage
          }

          vm.save (err) =>
            return callback err  if err
            group.addVm vm, (err)=>
              return callback err  if err
              if type is 'group'
                @addVmUsers vm, group, ->
                  callback null, vm
              else
                callback null, vm

  @addVmUsers = (vm, group, callback)->
    group.fetchMembers (err, members)->
      return callback err  if err
      members.forEach (member)->
        member.fetchUser (err, user)->
          if err then callback err
          else
            member.checkPermission group, 'sudoer', (err, hasPermission)->
              if err then handleError err
              else
                vm.update {
                  $addToSet: users: { id: user.getId(), sudo: hasPermission }
                }, callback

  # @getUsageTemplate = -> { cpu: 0, ram: 0, disk: 0 }

  # @calculateUsage = (account, groupSlug, callback)->
  #   nickname =
  #     if 'string' is typeof account then account
  #     else account.profile.nickname

  #   @all { name: ///$#{groupSlug}~#{nickname}~/// }, (err, vms) =>
  #     return callback err  if err?
  #     callback null, vms
  #       .map((vm) -> vm.usage)
  #       .reduce (acc, usage) ->
  #         for own field, val of usage
  #           acc[field] += val
  #           return acc
  #       , @getUsageTemplate()

  # @calculateUsage$ = permit 'list all vms',
  #   success: (client, groupSlug, callback)->
  #     {delegate} = client.connection
  #     @calculateUsage delegate, groupSlug, callback

  @fetchVMInfo = secure (client, hostname, callback)->
    {delegate} = client.connection

    delegate.fetchUser (err, user) ->
      return callback err  if err

      JVM.one
        hostname      : hostname
        users         : { $elemMatch: id: user.getId() }
      , (err, vm)->
        return callback err  if err
        return callback null, null  unless vm
        callback null,
          planCode    : vm.planCode
          planOwner   : vm.planOwner
          hostname    : vm.hostname

  @fetchAccountVmsBySelector = (account, selector, options, callback) ->
    [callback, options] = [options, callback]  unless callback

    options ?= {}
    # options.limit = Math.min options.limit ? 10, 10

    account.fetchUser (err, user) ->
      return callback err  if err

      selector.users = { $elemMatch: id: user.getId() }

      JVM.someData selector, { hostname: 1 }, options, (err, cursor)->
        return callback err  if err

        cursor.toArray (err, arr)->
          return callback err  if err
          callback null, arr.map (vm)-> vm.hostname

  @fetchVmsByContext = permit 'list all vms',
    success: (client, options, callback) ->
      {connection:{delegate}, context:{group}} = client
      JGroup = require './group'

      slug = group ? 'koding'

      JGroup.one {slug}, (err, group) =>
        return callback err  if err

        selector = groups: { $elemMatch: id: group.getId() }
        @fetchAccountVmsBySelector delegate, selector, options, callback

  @fetchVms = permit 'list all vms',
    success: (client, options, callback) ->
      {delegate} = client.connection
      @fetchAccountVmsBySelector delegate, {}, options, callback

    # TODO: let's implement something like this:
    # failure: (client, callback) ->
    #   @fetchDefaultVmByContext client, (err, vm)->
    #     return callback err  if err
    #     callback null, [vm]

  # @fetchDomains = permit 'list all vms',
  #   success:(client, alias, callback)->
  #     {delegate} = client.connection

  #     delegate.fetchUser (err, user) ->
  #       return callback err  if err

  #       selector =
  #         hostnameAlias : alias
  #         users         : { $elemMatch: id: user.getId(), owner: yes }

  #       JVM.one selector, {hostnameAlias:1}, (err, vm)->
  #         return callback err, []  if err or not vm
  #         callback null, vm.hostnameAlias or []

  @deleteVM = (vm, callback)->
    if vm.planCode is 'free'
      vm.remove callback
    else
      JRecurlySubscription.getSubscriptionsAll vm.planOwner,
        userCode : vm.planOwner
        planCode : vm.planCode
        $or      : [
          {status: 'active'}
          {status: 'canceled'}
        ]
      , (err, subs)->
        if err
          return callback new KodingError 'Unable to update subscription.'
        subs.forEach (sub)->
          if sub.status is 'canceled'
            vm.remove callback
          else if sub.quantity > 1
            sub.update sub.quantity - 1, (err, sub)->
              if err
                return callback new KodingError 'Unable to update subscription.'
              vm.remove callback
          else
            sub.terminate (err, newSub)->
              if err
                return callback new KodingError 'Unable to terminate payment'
              else
                vm.remove callback

  @removeByHostname = secure (client, hostname, callback)->
    {delegate} = client.connection

    delegate.fetchUser (err, user)=>
      return callback err  if err

      selector =
        hostname : hostname
        users    : { $elemMatch: id: user.getId(), owner: yes }

      JVM.one selector, (err, vm)=>
        return callback err  if err
        return callback new KodingError 'No such VM'  unless vm

        if vm.planOwner.indexOf("user_") > -1
          @deleteVM vm, callback
        else
          groupID = vm.planOwner.split('_')[1]

          JGroup = require './group'
          JGroup.one {_id: groupID}, (err, group)=>
            return callback err  if err
            JPermissionSet.checkPermission client, "delete vms", group,
            (err, hasPermission)=>
              return callback err  if err
              if hasPermission
                @deleteVM vm, callback

  do ->

    handleError = (err)-> console.error err  if err

    JGroup  = require './group'
    JUser   = require './user'

    addVm = ({ target, user, sudo, groups, groupSlug
               type, planCode, planOwner, webHome })->

      uid = 0
      hostnameAliases = JVM.createAliases {
        nickname : user.username
        type, uid, groupSlug
      }

      JVM.createDomains hostnameAliases

      vm = new JVM {
        planCode  : planCode
        planOwner : planOwner
        users     : [
          { id: user.getId(), sudo: yes, owner: yes }
        ]
        groups    : groups ? []
        hostname  : hostnameAliases[0]
        webHome
      }
      vm.save (err)-> target.addVm vm, handleError

    wrapGroup =(group)-> [ { id: group.getId() } ]

    uidFactory = (require 'koding-counter') {
      db          : JVM.getClient()
      counterName : 'uid'
      offset      : 1e6
    }

    uidFactory.reset (err, lastId)->
      console.log "UID counter is reset: %s", lastId

    JUser.on 'UserCreated', (user)->
      uidFactory.next (err, uid)->
        if err then handleError err
        else user.update { $set: { uid } }, handleError

    JGroup.on 'GroupCreated', ({group, creator})->
      group.fetchBundle (err, bundle)->
        console.log err, bundle
        if err then handleError err
        else if bundle and bundle.sharedVM
          creator.fetchUser (err, user)->
            if err then handleError err
            else
              # Following is just here to register this name in the counters collection
              ((require 'koding-counter') {
                db          : JVM.getClient()
                counterName : "#{group.slug}~"
                offset      : 0
              }).next ->

              addVm {
                user
                sudo        : yes
                type        : 'group'
                target      : group
                planCode    : 'free'
                planOwner   : "group_#{group._id}"
                groupSlug   : group.slug
                webHome     : group.slug
                groups      : wrapGroup group
              }

    JGroup.on 'GroupDestroyed', (group)->
      group.fetchVms (err, vms)->
        if err then handleError err
        else vms.forEach (vm)-> vm.remove handleError

    JGroup.on 'MemberAdded', ({group, member})->
      member.fetchUser (err, user)->
        if err then handleError err
        else if group.slug is 'koding'
          # Following is just here to register this name in the counters collection
          ((require 'koding-counter') {
            db          : JVM.getClient()
            counterName : "koding~#{member.profile.nickname}~"
            offset      : 0
          }).next ->

          # TODO: this special case for koding should be generalized for any group.
          addVm {
            user
            sudo      : yes
            type      : 'user'
            target    : member
            planCode  : 'free'
            planOwner : "user_#{member._id}"
            groupSlug : group.slug
            webHome   : user.username
            groups    : wrapGroup group
          }
        else
          member.checkPermission group, 'sudoer', (err, hasPermission)->
            if err then handleError err
            else
              group.fetchVms (err, vms)->
                if err then handleError err
                else vms.forEach (vm)->
                  vm.update {
                    $addToSet: users: { id: user.getId(), sudo: hasPermission }
                  }, handleError

    JGroup.on 'MemberRemoved', ({group, member})->
      member.fetchUser (err, user)->
        if err then handleError err
        else if group.slug is 'koding'
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
        if err then handleError err
        else
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
