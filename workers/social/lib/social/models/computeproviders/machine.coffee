
{ Module }  = require 'jraphical'
{ revive }  = require './computeutils'
KodingError = require '../../error'

{argv}      = require 'optimist'
KONFIG      = require('koding-config-manager').load("main.#{argv.c}")

module.exports = class JMachine extends Module

  { ObjectId, signature, daisy } = require 'bongo'

  @trait __dirname, '../../traits/protected'
  {permit} = require '../group/permissionset'

  @share()

  @set

    indexes             :
      kiteId            : 'unique'

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
        setProvisioner  :
          (signature String, Function)
        setDomain       :
          (signature String, Function)

    permissions         :
      'list machines'   : ['member']
      'populate users'  : ['member']
      'set provisioner' : ['member']
      'set domain'      : ['member']

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

      provisioners      :
        type            : [ ObjectId ]

      credential        : String
      users             : Array
      groups            : Array

      createdAt         : Date

      status            :

        modifiedAt      : Date

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


  @create = (data)->

    # JMachine.uid is a unique id which is generated from:
    #
    # 0     letter 'u'
    # 1     first letter of `username`
    # 2     first letter of `group slug`
    # 3     first letter of `provider`
    # 4..12 32-bit random hex string

    {user, group, provider} = data

    data.uid = "u#{user[0]}#{group[0]}#{provider[0]}#{(require 'hat')(32)}"
    data.createdAt = new Date()
    data.status  =
      state      : "NotInitialized"
      modifiedAt : data.createdAt

    { userSitesDomain } = KONFIG
    data.domain         = "#{data.uid}.#{user}.#{userSitesDomain}"
    data.provisioners  ?= [ ]

    return new JMachine data


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

      selector       ?= { }
      selector.users  = $elemMatch: id: user.getId()
      selector.groups = $elemMatch: id: group.getId()

      JMachine.some selector, limit: 30, (err, machines)->
        callback err, machines


  setProvisioner: permit 'set provisioner',

    success: revive

      shouldReviveClient   : yes
      shouldReviveProvider : no

    , (client, provisioner, callback)->

      { r: { group, user } } = client

      userId    = user.getId()
      approved  = no
      approved |= u.owner and u.id.equals userId  for u, i in @users

      if approved
        JProvisioner = require './provisioner'
        JProvisioner.one$ client, slug: provisioner, (err, provision)=>
          if err or not provision?
            callback new KodingError 'Provisioner not found'
          else
            @update $set: provisioners: [ provision.slug ], callback
      else
        callback new KodingError 'Access denied'


  reviveUsers: permit 'populate users',

    success: (client, callback)->

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

    success: (client, domain, callback)->

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
