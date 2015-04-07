
{ Module }  = require 'jraphical'
{ revive }  = require './computeutils'
KodingError = require '../../error'

{argv}      = require 'optimist'
KONFIG      = require('koding-config-manager').load("main.#{argv.c}")

module.exports = class JMachine extends Module

  { ObjectId, signature, daisy, secure } = require 'bongo'

  @trait __dirname, '../../traits/protected'

  {slugify} = require '../../traits/slugifiable'
  {permit}  = require '../group/permissionset'

  @share()

  @set

    indexes             :
      uid               : 'unique'
      slug              : 'sparse'
      users             : 'sparse'
      groups            : 'sparse'
      domain            : 'sparse'

    sharedEvents        :
      static            : [ ]
      instance          : [ ]

    sharedMethods       :
      static            :
        one             :
          (signature String, Function)
        some            :
          (signature Object, Function)
      instance          :
        deny            :
          (signature Function)
        approve         :
          (signature Function)
        reviveUsers     :
          (signature Object, Function)
        shareWith       :
          (signature Object, Function)
        setProvisioner  :
          (signature String, Function)
        setLabel        :
          (signature String, Function)
        share           :
          (signature Object, Function)
        unshare         :
          (signature Object, Function)

        # Disabled for now ~ GG
        # setAsOwner      :
        #   (signature Object, Function)
        # unsetAsOwner    :
        #   (signature Object, Function)


    permissions         :
      'list machines'   : ['member']
      'populate users'  : ['member']
      'set provisioner' : ['member']
      'set domain'      : ['member']
      'set label'       : ['member']

    schema              :

      uid               :
        type            : String
        required        : yes

      queryString       :
        type            : String

      ipAddress         :
        type            : String

      domain            :
        type            : String

      provider          :
        type            : String
        required        : yes

      label             :
        type            : String
        default         : -> ""

      slug              : String

      provisioners      :
        type            : [ ObjectId ]

      credential        : String
      users             : Array
      groups            : Array

      createdAt         : Date

      status            :

        modifiedAt      : Date
        reason          : String

        state           :
          type          : String
          enum          : ["Wrong type specified!", [

            # States which description ending with '...' means its an ongoing
            # proccess which you may get progress info about it
            #
            "NotInitialized"  # Initial state, machine instance does not exists
            "Building"        # Build started machine instance creating...
            "Starting"        # Machine is booting...
            "Running"         # Machine is physically running
            "Stopping"        # Machine is turning off...
            "Stopped"         # Machine is turned off
            "Rebooting"       # Machine is rebooting...
            "Terminating"     # Machine is getting destroyed...
            "Terminated"      # Machine is destroyed, not exists anymore
            "Unknown"         # Machine is in an unknown state
                              # needs to solved manually

          ]]

          default       : -> "NotInitialized"

      meta              : Object

      assignee          :
        inProgress      : Boolean
        assignedAt      : Date


  # Helpers
  # -------

  generateSlugFromLabel = ({user, group, label, index}, callback)->

    slug = _label = if index? then "#{label}-#{index}" else label
    slug = slugify slug

    JMachine.count {
      users : $elemMatch: id: user.getId()
      groups: $elemMatch: id: group.getId()
      slug
    }, (err, count)->

      return callback err  if err?

      if count is 0
        callback null, {slug, label: _label}
      else
        index ?= 0
        index += 1
        generateSlugFromLabel {user, group, label, index}, callback


  isOwner  = (user, machine) ->

    userId = user.getId()

    owner  = no
    owner |= u.sudo and u.owner and u.id.equals userId  for u in machine.users

    return owner


  excludeUser = (options)->

    { users, user, permanent } = options

    userId   = user.getId()
    newUsers = []

    for u in users
      unless userId.equals u.id
        newUsers.push u
      else if not permanent? and u.permanent
        newUsers.push u

    return newUsers


  addUser = (users, options)->

    # asOwner option is disabled for now ~ GG
    # passing False for owner
    {user, asOwner, permanent} = options

    newUsers = excludeUser { users, user, permanent }

    userId = user.getId()
    for u in newUsers
      break  if inList = userId.equals u.id

    unless inList
      newUsers.push {
        id       : user.getId()
        owner    : no
        approved : no
        permanent
      }

    return newUsers


  informAccounts = (users, machineUId, action) ->

    users.forEach (user)->
      user.fetchOwnAccount (err, account)->
        return if err or not account
        account.sendNotification 'MachineListUpdated', {machineUId, action}


  # Private Methods
  # ---------------

  # Static Methods

  @create = (data, callback)->

    # JMachine.uid is a unique id which is generated from:
    #
    # 0     letter 'u'
    # 1     first letter of `username`
    # 2     first letter of `group slug`
    # 3     first letter of `provider`
    # 4..12 32-bit random hex string

    {user, group, provider} = data

    data.user  = username  = user.username
    data.group = groupSlug = group.slug

    data.users     = [{ id: user.getId(), sudo: yes, owner: yes }]
    data.groups    = [{ id: group.getId() }]

    data.uid = "u#{username[0]}#{groupSlug[0]}#{provider[0]}#{(require 'hat')(32)}"
    data.createdAt = new Date()

    data.label    ?= data.uid

    data.assignee  =
      inProgress   : no
      assignedAt   : data.createdAt

    data.status    =
      state        : "NotInitialized"
      modifiedAt   : data.createdAt

    if provider is "koding"
      { userSitesDomain } = KONFIG
      data.domain = "#{data.uid}.#{username}.#{userSitesDomain}"
    else
      data.domain = "#{data.uid}.#{username}"

    data.provisioners  ?= [ ]

    {label} = data

    generateSlugFromLabel {user, group, label}, (err, {slug, label})->

      return callback err  if err?

      data.label = label
      data.slug  = slug

      machine = new JMachine data
      machine.save (err)->

        if err
          callback err
          console.warn "Failed to create Machine for ", {username, groupSlug}
        else
          callback null, machine


  @getSelectorFor = (client, {machineId, owner})->

    { r: { group, user } } = client

    userObj    = if owner then {sudo: yes, owner: yes} else {}
    userObj.id = user.getId()

    selector  =
      $or     : [
        { _id : ObjectId machineId }
        { uid : machineId }
      ]
      users   : $elemMatch: userObj
      groups  : $elemMatch: id: group.getId()

    return selector


  # Instance Methods

  destroy: (client, callback)->

    { r: { user } } = client

    unless isOwner user, this
      return callback new KodingError 'Access denied'

    @remove callback


  addUsers: (options, callback)->

    {targets, asOwner, permanent} = options

    users = @users.splice 0

    for user in targets
      users = addUser users, {user, asOwner, permanent}

    if users.length > 10
      callback new KodingError \
        "Machine sharing is limited up to 10 users."
    else
      @update $set: { users }, (err) =>
        informAccounts targets, @getAt('uid'), 'added'
        callback err


  removeUsers: (options, callback)->

    {targets, permanent, inform} = options

    users = @users.splice 0

    for user in targets
      users = excludeUser { users, user, permanent }

    @update $set: { users }, (err) =>
      informAccounts targets, @getAt('uid'), 'removed'  if inform
      callback err


  shareWith: (options, callback)->

    { target, asUser, asOwner, permanent, inform } = options

    asUser  ?= yes
    asOwner ?= no
    inform  ?= yes

    unless target?
      return callback new KodingError "Target required."

    JUser = require '../user'
    JName = require '../name'

    JName.fetchModels target, (err, result)=>

      if err or not result?
        return callback new KodingError "Target not found."

      targets = (target.models[0]  for target in result)

      [ target ] = targets

      if target instanceof JUser

        if asUser
        then @addUsers {targets, asOwner, permanent}, callback
        else @removeUsers {targets, permanent, inform}, callback

      else
        callback new KodingError "Target does not support machines."


  fetchOwner: (callback) ->

    owner = user for user in @users when user.owner and user.sudo
    errCb = -> callback new KodingError 'Owner user not found'
    return errCb()  unless owner

    JUser = require '../user'
    JUser.one _id: owner.id, (err, user) ->
      return errCb()  if err or not user
      user.fetchOwnAccount callback


  # Shared Methods
  # --------------

  # Static Methods

  @one$ = permit 'list machines',

    success: revive

      shouldReviveClient   : yes
      shouldReviveProvider : no

    , (client, machineId, callback)->

      selector = @getSelectorFor client, {machineId}

      JMachine.one selector, (err, machine)->
        callback err, machine


  @some$ = permit 'list machines',

    success: revive

      shouldReviveClient   : yes
      shouldReviveProvider : no

    , (client, selector, callback)->

      { r: { group, user } } = client

      selector             ?= {}
      selector['users.id']  = user.getId()

      JMachine.some selector, limit: 30, (err, machines)->
        callback err, machines


  @fetchByUsername = (username, callback)->

    JUser = require '../user'
    JUser.one {username}, (err, user)->

      return callback err  if err
      return callback new KodingError "User not found."  unless user

      selector        =
        'users.id'    : user.getId()
        'users.sudo'  : yes
        'users.owner' : yes

      JMachine.some selector, limit: 30, (err, machines)->
        callback err, machines


  # Instance Methods

  setProvisioner: permit 'set provisioner',

    success: revive

      shouldReviveClient   : yes
      shouldReviveProvider : no

    , (client, provisioner, callback)->

      { r: { user } } = client

      unless isOwner user, this
        return callback new KodingError 'Access denied'

      JProvisioner = require './provisioner'
      JProvisioner.one$ client, slug: provisioner, (err, provision)=>
        if err or not provision?
          callback new KodingError 'Provisioner not found'
        else
          @update $set: provisioners: [ provision.slug ], callback


  reviveUsers: permit 'populate users',

    success: revive

      shouldReviveClient   : yes
      shouldReviveProvider : no

    , (client, options, callback)->

      { r: { user } } = client
      {permanentOnly} = options

      unless isOwner user, this
        return callback new KodingError 'Access denied'

      JUser = require '../user'

      accounts = []
      queue    = []

      (@users ? []).forEach (_user)->

        return  if permanentOnly and not _user.permanent

        queue.push -> JUser.one _id: _user.id, (err, user)->
          if not err? and user
            user.fetchOwnAccount (err, account)->
              if not err? and account?
                accounts.push account
              queue.next()
          else
            queue.next()

      queue.push ->
        callback null, accounts

      daisy queue


  setLabel: permit 'set label',

    success: revive

      shouldReviveClient   : yes
      shouldReviveProvider : no

    , (client, label, callback)->

      { r: { user, group } } = client

      unless isOwner user, this
        return callback new KodingError 'Access denied'

      kallback = (err, slug)->
        if err?
        then callback err
        else callback null, slug

      slug = slugify label

      if slug is ""
        return callback new KodingError "Nickname cannot be empty"

      if slug isnt @slug
        generateSlugFromLabel { user, group, label }, (err, {slug, label})=>
          return callback err  if err?
          @update $set: { slug, label }, (err)-> kallback err, slug
      else
        @update $set: { label }, (err)-> kallback err, slug


  # .shareWith can be used like this:
  #
  # JMachineInstance.shareWith {
  #   asUser: yes, asOwner: no, target: ["gokmen", "dicle"], permanent: no}, cb
  # }
  #                        user slugs ->  ^^^^^^ ,  ^^^^^
  #
  # ps. permanent option requires a valid paid subscription
  #

  shareWith$: permit 'populate users',

    success : revive

      shouldReviveClient   : yes
      shouldReviveProvider : no
      shouldLockProcess    : yes

    , (client, options, callback)->

      { r: { user } } = client

      # Only an owner of this machine can modify it
      unless isOwner user, this
        return callback new KodingError "Access denied"

      { target, permanent, asUser } = options

      # At least one target is required
      if not target or target.length is 0
        return callback new KodingError "A target required."

      # Max 9 target can be passed
      if target.length > 9
        return callback new KodingError \
          "It is not allowed to change more than 9 state at once."

      # Owners cannot unassign them from a machine
      # Only another owner can unassign any other owner
      if user.username in target
        return callback \
          new KodingError "You are not allowed to change your own state!"

      # For Koding provider credential field is username
      # and we don't allow them to be removed from users
      if @provider is 'koding' and @credential in target
        return callback \
          new KodingError "It is not allowed to change owner state!"

      # If it's a call for unshare then no need to check
      # any other state for it
      if asUser is no
        JMachine::shareWith.call this, options, callback

        return

      # Permanent option is only valid for paid accounts
      # if its passed then we need to check payment
      #
      if permanent # and @provider is 'koding'
                   # TODO: we can limit this for koding provider only ~ GG

        Payment = require '../payment'
        Payment.subscriptions client, {}, (err, subscription)=>

          if err? or not subscription? or subscription.planTitle is 'free'
            return callback \
              new KodingError "You don't have a paid subscription!"

          JMachine::shareWith.call this, options, callback

      else

        JMachine::shareWith.call this, options, callback


  share: secure (client, users, callback) ->

    options = target: users, asUser: yes
    @shareWith$ client, options, callback


  unshare: secure (client, users, callback)->

    options = target: users, asUser: no

    {connection:{delegate}} = client
    {profile:{nickname}}    = delegate

    if users.length is 1 and users[0] is nickname
    then @shareWith options, callback
    else @shareWith$ client, options, callback


  # setting owner disabled for now ~ GG

  # setAsOwner: secure (client, users, callback) ->
  #   options = target: users, asUser: yes, asOwner: yes
  #   @shareWith$ client, options, callback

  # unsetAsOwner: secure (client, users, callback) ->
  #   options = target: users, asUser: yes, asOwner: no
  #   @shareWith$ client, options, callback


  approve: secure revive

    shouldReviveClient   : yes
    shouldLockProcess    : yes
    shouldReviveProvider : no
    hasOptions           : no

  , (client, callback)->

    { r: { user } } = client

    # An owner cannot approve their own machine
    if isOwner user, this
      return callback null

    JMachine.update
      "_id"      : @getId()
      "users.id" : user._id
    , $set       : "users.$.approved" : yes
    , (err)-> callback err


  deny: secure revive

    shouldReviveClient   : yes
    shouldLockProcess    : yes
    shouldReviveProvider : no
    hasOptions           : no

  , (client, callback)->

    { r: { user } } = client

    # An owner cannot deny their own machine
    if isOwner user, this
      return callback null

    options =
      target    : [user.username]
      asUser    : no
      inform    : no
      permanent : yes

    @shareWith options, (err)->
      callback err
