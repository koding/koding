
{ Module }  = require 'jraphical'
{ revive }  = require './computeutils'
KodingError = require '../../error'

{argv}      = require 'optimist'
KONFIG      = require('koding-config-manager').load("main.#{argv.c}")

module.exports = class JMachine extends Module

  { ObjectId, signature, daisy } = require 'bongo'

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
        reviveUsers     :
          (signature Function)
        shareWith     :
          (signature Object, Function)
        setProvisioner  :
          (signature String, Function)
        setLabel        :
          (signature String, Function)

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

    slug = if index? then "#{label}-#{index}" else label
    slug = slugify slug

    JMachine.count {
      users : $elemMatch: id: user.getId()
      groups: $elemMatch: id: group.getId()
      slug
    }, (err, count)->

      return callback err  if err?

      if count is 0
        callback null, slug
      else
        index ?= 0
        index += 1
        generateSlugFromLabel {user, group, label, index}, callback


  isOwner  = (user, machine) ->

    userId = user.getId()

    owner  = no
    owner |= u.owner and u.id.equals userId  for u, i in machine.users

    return owner


  removeUser = (users, user)->

    userId   = user.getId()
    newUsers = []

    for u in users
      newUsers.push u  unless userId.equals u.id

    return newUsers


  addUser = (users, user, owner)->

    newUsers = removeUser users, user
    newUsers.push { id: user.getId(), owner }

    return newUsers


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

    generateSlugFromLabel {user, group, label}, (err, slug)->

      return callback err  if err?

      data.slug = slug

      machine = new JMachine data
      machine.save (err)->

        if err
          callback err
          console.warn "Failed to create Machine for ", {username, groupSlug}
        else
          callback null, machine


  # Instance Methods

  addUsers: (usersToAdd, owner, callback)->

    users = @users.splice 0

    for user in usersToAdd
      users = addUser users, user, owner

    if users.length > 10
      callback new KodingError \
        "Machine sharing is limited up to 10 users."
    else
      @update $set: { users }, callback


  removeUsers: (usersToRemove, callback)->

    users = @users.splice 0

    for user in usersToRemove
      users = removeUser users, user

    @update $set: { users }, callback


  shareWith: (options, callback)->

    { target, user, owner } = options
    user  ?= yes
    owner ?= no

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

        if user
        then @addUsers targets, owner, callback
        else @removeUsers targets, callback

      else
        callback new KodingError "Target does not support machines."



  # Shared Methods
  # --------------

  # Static Methods

  @one$ = permit 'list machines',

    success: revive

      shouldReviveClient   : yes
      shouldReviveProvider : no

    , (client, machineId, callback)->

      { r: { group, user } } = client

      selector  =
        $or     : [
          { _id : ObjectId machineId }
          { uid : machineId }
        ]
        users   : $elemMatch: id: user.getId()
        groups  : $elemMatch: id: group.getId()

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

    , (client, callback)->

      { r: { user } } = client

      unless isOwner user, this
        return callback new KodingError 'Access denied'

      JUser = require '../user'

      accounts = []
      queue    = []

      (@users ? []).forEach (_user)->
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
        generateSlugFromLabel { user, group, label }, (err, slug)=>
          return callback err  if err?
          @update $set: { slug, label }, (err)-> kallback err, slug
      else
        @update $set: { label }, (err)-> kallback err, slug


  # .shareWith can be used like this:
  #
  # JMachineInstance.shareWith {
  #   user: yes, owner: no, target: ["gokmen", "dicle"]}, cb
  # }
  #                    user slugs ->  ^^^^^^ ,  ^^^^^

  shareWith$: permit 'populate users',

    success : revive

      shouldReviveClient   : yes
      shouldReviveProvider : no

    , (client, options, callback)->

      { r: { user } } = client

      unless isOwner user, this
        return callback new KodingError "Access denied"

      { target } = options

      if target.length > 9
        return callback new KodingError \
          "It is not allowed to change more than 9 state at once."

      # Owners cannot unassign them from a machine
      # Only another owner can unassign any other owner
      if user.username in target
        return callback \
          new KodingError "It is not allowed to change owner state!"

      JMachine::shareWith.call this, options, callback
