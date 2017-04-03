{ Module }  = require 'jraphical'
{ revive }  = require './computeutils'
KodingError = require '../../error'
async       = require 'async'


module.exports = class JMachine extends Module

  { ObjectId, signature, secure } = require 'bongo'

  @trait __dirname, '../../traits/protected'
  @trait __dirname, '../../traits/notifiable'

  { slugify } = require '../../traits/slugifiable'
  { permit }  = require '../group/permissionset'

  @share()

  @set

    indexes             :
      uid               : 'unique'
      slug              : 'sparse'
      users             : 'sparse'
      groups            : 'sparse'
      domain            : 'sparse'
      status            : 'sparse'
      channelId         : 'sparse'

    sharedEvents        :
      static            : [ ]
      instance          : [ ]

    sharedMethods       :
      static            :
        one             :
          (signature Object, Function)
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
        setChannelId    :
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
        default         : -> ''

      slug              : String

      provisioners      :
        type            : [ ObjectId ]

      credential        : String
      users             : [ Object ]
      groups            : [ Object ]

      createdAt         : Date

      status            :

        modifiedAt      : Date
        reason          : String

        state           :
          type          : String
          enum          : ['Wrong type specified!', [

            # States which description ending with '...' means its an ongoing
            # proccess which you may get progress info about it
            #
            'NotInitialized'  # Initial state, machine instance does not exists
            'Building'        # Build started machine instance creating...
            'Starting'        # Machine is booting...
            'Running'         # Machine is physically running
            'Stopping'        # Machine is turning off...
            'Stopped'         # Machine is turned off
            'Rebooting'       # Machine is rebooting...
            'Terminating'     # Machine is getting destroyed...
            'Terminated'      # Machine is destroyed, not exists anymore
            'Unknown'         # Machine is in an unknown state
                              # needs to solved manually

          ]]

          default       : -> 'NotInitialized'

      meta              : Object

      assignee          :
        inProgress      : Boolean
        assignedAt      : Date

      generatedFrom     :
        templateId      : ObjectId
        revision        : String

      channelId         :
        type            : String


  # Helpers
  # -------

  generateSlugFromLabel = ({ user, group, label, index }, callback) ->

    slug = _label = if index? then "#{label}-#{index}" else label
    slug = slugify slug

    JMachine.count {
      'status.state' : { $ne: 'Terminated' }
      users          :
        $elemMatch   :
          id         : user.getId()
      groups         :
        $elemMatch   :
          id         : group.getId()
      slug
    }, (err, count) ->

      return callback err  if err?

      if count is 0
        callback null, { slug, label: _label }
      else
        index ?= 0
        index += 1
        generateSlugFromLabel { user, group, label, index }, callback


  isOwner  = (user, machine) ->

    userId = user.getId()

    owner  = no
    owner |= u.sudo and u.owner and u.id.equals userId  for u in machine.users

    return owner


  excludeUser = (options) ->

    { users, user, permanent, force } = options

    userId   = user.getId()
    newUsers = []

    for u in users
      unless userId.equals u.id
        newUsers.push u
      else if not permanent and u.permanent and not force
        newUsers.push u

    return newUsers


  addUser = (users, options) ->

    { user, asOwner, permanent } = options

    newUsers = excludeUser { users, user, permanent }

    userId = user.getId()
    for u in newUsers
      break  if inList = userId.equals u.id

    unless inList
      newUsers.push {
        id       : user.getId()
        username : user.username
        owner    : asOwner
        approved : no
        permanent
      }

    return newUsers


  informAccounts = (options) ->

    { users, machineUId, action, permanent, group } = options

    users.forEach (user) ->
      user.fetchOwnAccount (err, account) ->
        return  if err or not account
        account.sendNotification 'MachineListUpdated', { machineUId, action, permanent, group }


  validateTarget = (target, user) ->

    # At least one target is required
    if not target or target.length is 0
      return new KodingError 'A target required.'

    # Max 9 target can be passed
    if target.length > 9
      return new KodingError \
        'It is not allowed to change more than 9 state at once.'

    # Owners cannot unassign them from a machine
    # Only another owner can unassign any other owner
    if user.username in target
      return new KodingError \
        'You are not allowed to change your own state!'


  checkFields = (data, required) ->
    for field in required when not data[field]
      return new KodingError "#{field} is not set!"


  # Private Methods
  # ---------------

  # Static Methods

  @create = (data, callback) ->

    # JMachine.uid is a unique id which is generated from:
    #
    # 0     letter 'u'
    # 1     first letter of `username`
    # 2     first letter of `group slug`
    # 3     first letter of `provider`
    # 4..12 32-bit random hex string

    return callback err  if err = checkFields data, ['user', 'group', 'provider']

    { user, group, provider } = data

    data.user  = username  = user.username
    data.group = groupSlug = group.slug

    # Users list can be provided before machine create
    # We also need to make sure that the real owner of the
    # machine is in list. ~ GG
    userObj    =
      id       : user.getId()
      sudo     : yes
      owner    : yes
      username : user.username

    if Array.isArray(data.users) and data.users.length > 0
      data.users.push userObj
    else
      data.users   = [ userObj ]

    data.groups    = [{ id: group.getId() }]

    data.uid = "u#{username[0]}#{groupSlug[0]}#{provider[0]}#{(require 'hat')(32)}"
    data.createdAt = new Date()

    data.label    ?= data.uid

    data.assignee  =
      inProgress   : no
      assignedAt   : data.createdAt

    data.status    =
      state        : 'NotInitialized'
      modifiedAt   : data.createdAt

    data.domain = "#{data.uid}.#{username}"

    data.provisioners  ?= [ ]

    { label } = data

    generateSlugFromLabel { user, group, label }, (err, { slug, label }) ->

      return callback err  if err?

      data.label = label
      data.slug  = slug

      machine = new JMachine data
      machine.save (err) ->

        if err
          callback err
          console.warn 'Failed to create Machine for ', { username, groupSlug }
        else
          callback null, machine


  @getSelectorFor = (client, { machineId, owner }) ->

    { r: { group, user } } = client

    userObj    = if owner then { sudo: yes, owner: yes } else {}
    userObj.id = user.getId()

    selector       =
      $or          : [
        { uid      : machineId }
      ]
      users        :
        $elemMatch : userObj
      groups       :
        $elemMatch :
          id       : group.getId()

    # ObjectId throws error when a string passed to it ~ GG
    try
      asObjectId = ObjectId machineId
      selector.$or.push { _id : asObjectId }

    return selector

  # Instance Methods

  destroy: (client, callback) ->

    { r: { user } } = client

    unless isOwner user, this
      return callback new KodingError 'Access denied'

    @remove callback


  addUsers: (options, callback) ->

    { targets, asOwner, permanent, group, inform } = options

    users   = @users.slice 0
    inform ?= yes

    for user in targets
      users = addUser users, { user, asOwner, permanent }

    if users.length > 50
      callback new KodingError \
        'Machine sharing is limited up to 50 users.'
    else
      @update { $set: { users } }, (err) =>

        if inform then informAccounts
          users       : targets
          machineUId  : @getAt('uid')
          action      : 'added'
          group       : group

        callback err


  removeUsers: (options, callback) ->

    { targets, permanent, inform, force, group } = options

    users = @users.slice 0

    for user in targets
      users = excludeUser { users, user, permanent, force }

    @update { $set: { users } }, (err) =>
      if inform
        informAccounts {
          users       : targets
          machineUId  : @getAt('uid')
          action      : 'removed'
          permanent   : permanent
          group       : group
        }

      callback err


  shareWith: (options, callback) ->

    { target, asUser, asOwner, permanent, inform, group } = options

    asUser  ?= yes
    asOwner ?= no
    inform  ?= yes

    unless target?
      return callback new KodingError 'Target required.'

    JUser = require '../user'
    JName = require '../name'

    JName.fetchModels target, (err, result) =>

      if err or not result?
        return callback new KodingError 'Target not found.'

      targets = (target.models[0]  for target in result)

      [ target ] = targets

      if target instanceof JUser

        if asUser
        then @addUsers { targets, asOwner, permanent, group }, callback
        else @removeUsers { targets, permanent, inform, group }, callback

      else
        @removeInvalidUsers { group }, callback


  # Fetch machine's shared users and fetch those users' JUser document
  # and remove the user from machine share list if the user.status is deleted
  removeInvalidUsers: (options, callback) ->

    JUser = require '../user'
    queue = []
    users = @users.slice 0
    usersToBeRemoved = []
    { group } = options

    users.forEach (user) ->
      return  if user.sudo and user.owner
      queue.push (next) ->
        JUser.one { _id: user.id }, (err, _user) ->
          if err or not _user or _user.status is 'deleted'
            usersToBeRemoved.push _user

          next()

    queue.push (next) =>
      if usersToBeRemoved.length is 0
        next new KodingError 'Target does not support machines.'
      else
        @removeUsers { targets: usersToBeRemoved, force: yes, group }, (err) ->
          next err

    async.series queue, callback


  fetchOwner: (callback) ->

    owner = user for user in @users when user.owner and user.sudo
    errCb = -> callback new KodingError 'Owner user not found'
    return errCb()  unless owner

    JUser = require '../user'
    JUser.one { _id: owner.id }, (err, user) ->
      return errCb()  if err or not user
      user.fetchOwnAccount callback


  # Shared Methods
  # --------------

  # Static Methods

  @one$ = permit 'list machines',

    success: revive

      shouldReviveClient   : yes
      shouldReviveProvider : no

    , (client, query, callback) ->

      { _id, uid } = query
      selector = @getSelectorFor client, { machineId: _id ? uid }

      JMachine.one selector, (err, machine) ->
        callback err, machine


  @some$ = permit 'list machines',

    success: revive

      shouldReviveClient   : yes
      shouldReviveProvider : no

    , (client, selector, callback) ->

      { r: { group, user } } = client

      selector             ?= {}
      selector['users.id']  = user.getId()
      selector['groups.id'] = group.getId()

      JMachine.some selector, { limit: 60 }, (err, machines) ->
        callback err, machines


  @fetchByUsername = (username, callback) ->

    JUser = require '../user'
    JUser.one { username }, (err, user) ->

      return callback err  if err
      return callback new KodingError 'User not found.'  unless user

      selector        =
        'users.id'    : user.getId()
        'users.sudo'  : yes
        'users.owner' : yes

      JMachine.some selector, { limit: 60 }, (err, machines) ->
        callback err, machines


  # Instance Methods

  setProvisioner: permit 'set provisioner',

    success: revive

      shouldReviveClient   : yes
      shouldReviveProvider : no

    , (client, provisioner, callback) ->

      { r: { user } } = client

      unless isOwner user, this
        return callback new KodingError 'Access denied'

      JProvisioner = require './provisioner'
      JProvisioner.one$ client, { slug: provisioner }, (err, provision) =>
        if err or not provision?
          callback new KodingError 'Provisioner not found'
        else
          @update { $set: { provisioners: [ provision.slug ] } }, callback


  reviveUsers: permit 'populate users',

    success: revive

      shouldReviveClient   : yes
      shouldReviveProvider : no

    , (client, options, callback) ->

      { r: { user } } = client
      { permanentOnly } = options

      unless isOwner user, this
        return callback new KodingError 'Access denied'

      JUser = require '../user'

      accounts = []
      queue    = []

      (@users ? []).forEach (_user) ->

        return  if permanentOnly and not _user.permanent

        queue.push (next) -> JUser.one { _id: _user.id }, (err, user) ->
          if not err? and user
            user.fetchOwnAccount (err, account) ->
              if not err? and account?
                accounts.push account
              next()
          else
            next()

      async.series queue, -> callback null, accounts


  setLabel: permit 'set label',

    success: revive

      shouldReviveClient   : yes
      shouldReviveProvider : no

    , (client, label, callback) ->

      { r: { user, group } } = client

      unless isOwner user, this
        return callback new KodingError 'Access denied'

      kallback = (err, slug) ->
        if err?
        then callback err
        else callback null, slug

      slug = slugify label

      if slug is ''
        return callback new KodingError 'Nickname cannot be empty'

      notifyOptions =
        group   : client?.context?.group
        target  : 'group'

      if slug isnt @slug
        generateSlugFromLabel { user, group, label }, (err, { slug, label }) =>
          return callback err  if err?
          @updateAndNotify notifyOptions, { $set: { slug , label } }, (err) -> kallback err, slug
      else
        @updateAndNotify notifyOptions, { $set: { label } }, (err) -> kallback err, slug


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

    , (client, options, callback) ->

      { r: { user, group } } = client

      # set group data for future notification operations, wont be used in
      # machine sharing
      options.group = client.context.group

      # Only an owner of this machine can modify it
      unless isOwner user, this
        return callback new KodingError 'Access denied'

      { target } = options

      if err = validateTarget target, user
      then callback err
      else JMachine::shareWith.call this, options, callback


  share: secure (client, users, callback) ->

    options = { target: users, asUser: yes }
    @shareWith$ client, options, callback


  unshare: secure (client, users, callback) ->

    options = { target: users, asUser: no }

    { connection:{ delegate } } = client
    { profile:{ nickname } }    = delegate

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

  , (client, callback) ->

    { r: { user, group } } = client

    # An owner cannot approve their own machine
    if isOwner user, this
      return callback null

    JMachine.update {
      '_id'      : @getId()
      'users.id' : user._id
    }, { $set : { 'users.$.approved' : yes } }
    , (err) =>
      options = { action: 'approve', @uid, group: group.slug, machineId: @getId() }
      client.connection.delegate.sendNotification 'MachineShareActionTaken', options
      callback err


  deny: secure revive

    shouldReviveClient   : yes
    shouldLockProcess    : yes
    shouldReviveProvider : no
    hasOptions           : no

  , (client, callback) ->

    { r: { user, group } } = client

    # An owner cannot deny their own machine
    if isOwner user, this
      return callback null

    options =
      target    : [user.username]
      asUser    : no
      inform    : no
      permanent : yes

    @shareWith options, (err) =>
      options               = { action: 'deny', @uid, group: group.slug, machineId: @getId() }
      [ owner ]             = @users.filter (user) -> return user.owner
      { notifyByUsernames } = require '../notify'

      client.connection.delegate.sendNotification 'MachineShareActionTaken', options
      notifyByUsernames [ owner.username ], 'MachineShareListUpdated', options

      callback err


  @shareByUId = secure (client, uid, options, callback) ->

    JMachine.one { uid }, (err, machine) ->

      return callback err  if err
      return callback 'Machine is not found'  unless machine

      machine.shareWith$ client, options, (err) ->

        callback err, machine


  setChannelId: permit 'set label',

    success: revive

      shouldReviveClient   : yes
      shouldLockProcess    : yes
      shouldReviveProvider : no

    , (client, options, callback) ->

      { channelId } = options
      { r: { user } } = client

      # Only an owner of this machine can modify it
      unless isOwner user, this
        return callback new KodingError 'Access denied'

      if channelId

        if typeof channelId isnt 'string' or channelId.length > 20
          return callback new KodingError 'Invalid ChannelID provided'

        @update { $set: { channelId } }, (err) =>
          return callback err  if err
          return callback null, this

      else

        @update { $unset: { channelId: 1 } }, (err) =>
          return callback err  if err

          delete this.data.channelId
          delete this.channelId

          return callback null, this
