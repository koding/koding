
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



  @one$: permit 'list machines',

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


  @some$: permit 'list machines',

    success: revive

      shouldReviveClient   : yes
      shouldReviveProvider : no

    , (client, selector, callback)->

      { r: { group, user } } = client

      selector             ?= {}
      selector['users.id']  = user.getId()

      JMachine.some selector, limit: 30, (err, machines)->
        callback err, machines



  isOwner  = (user, machine) ->

    userId = user.getId()

    owner  = no
    owner |= u.owner and u.id.equals userId  for u, i in machine.users

    return owner


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


  setDomain: permit 'set domain',

    success: revive

      shouldReviveClient   : yes
      shouldReviveProvider : no

    , (client, domain, callback)->

      { r: { user } } = client

      unless isOwner user, this
        return callback new KodingError 'Access denied'

      { nickname } = client.connection.delegate.profile
      { userSitesDomain } = KONFIG

      suffix  = "#{nickname}.#{userSitesDomain}"
      _suffix = suffix.replace ".", "\\."

      unless ///(^|\.)#{_suffix}$///.test domain
        return callback new KodingError \
          "Domain is invalid, it needs to be end with #{suffix}", "INVALIDDOMAIN"

      JMachine.count {domain}, (err, count)=>

        if err or count > 0
          return callback new KodingError \
            "The domain #{domain} already exists", "DUPLICATEDOMAIN"

        @update $set: { domain }, (err)-> callback err


  setLabel: permit 'set domain',

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


  addUser: (user, owner, callback)->

    userId = user.getId()
    users  = []

    for u in @users
      users.push u  unless userId.equals u.id

    users.push { id: userId, owner }

    @update $set: { users }, callback


  removeUser: (user, callback)->

    userId = user.getId()
    users  = []

    for u in @users
      users.push u  unless userId.equals u.id

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

      [ target ] = result.models

      if target instanceof JUser

        if user
        then @addUser target, owner, callback
        else @removeUser target, callback

      else
        callback new KodingError "Target does not support machines."


  # .share can be used like this:
  #
  # JMachineInstance.shareWith { user: yes, owner: no, target: "gokmen"}, cb
  #                                                user slug -> ^^^^^^

  shareWith$: permit 'populate users',

    success: revive

      shouldReviveClient   : yes
      shouldReviveProvider : no

    , (client, options, callback)->

      { r: { user } } = client

      unless isOwner user, this
        return callback new KodingError "Access denied"

      { target } = options

      # Owners cannot unassign them from a machine
      # Only another owner can unassign any other owner
      if user.username is target
        return callback \
          new KodingError "It's not allowed to change owner's state!"

      JMachine::shareWith.call this, options, callback
