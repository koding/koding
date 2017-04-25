debug          = (require 'debug') 'remote:api:jmachine'
Promise        = require 'bluebird'
_              = require 'lodash'
kd             = require 'kd'
remote         = require('../remote')


doesQueryStringValid  = require 'app/util/doesQueryStringValid'
nick                  = require 'app/util/nick'
globals               = require 'globals'

runMiddlewares        = require 'app/util/runMiddlewares'
TestMachineMiddleware = require 'app/providers/middlewares/testmachine'


module.exports = class JMachine extends remote.api.JMachine

  @getMiddlewares = ->
    return [
      TestMachineMiddleware.JMachine
    ]

  @State = {

    'NotInitialized'  # Initial state, machine instance does not exists
    'Building'        # Build started machine instance is being created...
    'Starting'        # Machine is booting...
    'Running'         # Machine is physically running
    'Stopping'        # Machine is turning off...
    'Stopped'         # Machine is turned off
    'Rebooting'       # Machine is rebooting...
    'Terminating'     # Machine is being destroyed...
    'Terminated'      # Machine is destroyed, does not exist anymore
    'Updating'        # Machine is being updated by provisioner
    'Unknown'         # Machine is in an unknown state
                      # needs to be resolved manually
  }

  @Type = {

    Own: 'own'
    Collaboration: 'collaboration'
    Shared: 'shared'
    Reassigned: 'reassigned'

  }

  stop: ->
    kd.singletons.computeController.stop this

  start: ->
    kd.singletons.computeController.start this

  constructor: ->

    super

    @fs =
      create: (options = {}, callback) =>
        options.machine = this
        require('../util/fs/fsitem').create options, callback

    @once 'ready', => @readyState = yes
    @fetchInfo => @emit 'ready'


  ready: (listener) ->
    if @readyState then kd.utils.defer listener
    else @once 'ready', listener


  getName: ->

    { uid, label, ipAddress } = this

    return label or ipAddress or uid or "one of #{nick()}'s machines"


  invalidateKiteCache: ->

    currentKite = @getBaseKite no
    currentKite.disconnect()

    kd.singletons.computeController.invalidateCache @_id


  getBaseKite: (createIfNotExists = yes) ->

    { kontrol } = kd.singletons

    # this is a chance for other middlewares to inject their own kite/klient.
    testKlient = runMiddlewares.sync this, 'getBaseKite', createIfNotExists

    return testKlient  if testKlient

    klient = kontrol.kites?.klient?[@uid]
    return klient  if klient

    if createIfNotExists and doesQueryStringValid @queryString

      debug 'getBaseKite: machine ready getting from kontrol'
      kontrol.getKite { name: 'klient', @queryString, correlationName: @uid }

    else

      debug 'getBaseKite: machine not ready'
      {
        init       : -> Promise.reject()
        connect    : kd.noop
        disconnect : kd.noop
        ready      : kd.noop
      }


  fetchInfo: (callback = kd.noop) ->

    owner = @getOwner()

    kallback = (info = {}) =>
      callback null, @info = _.merge {},
        home     : "/home/#{owner}"
        groups   : [owner, 'sudo']
        username : owner
      , info

    if @isRunning()
      kite = @getBaseKite()
      kite.init().then ->
        kite.klientInfo()
          .then (info) ->
            kallback info
            return info
          .timeout globals.COMPUTECONTROLLER_TIMEOUT
          .catch (err) ->
            kd.warn '[Machine][fetchInfo] Failed to get klient.info', err
            kallback()
    else
      kallback()

    return null


  getOwner: ->

    switch @provider
      when 'managed'
        return @credential
      else # Use users array for other types of providers ~ GG
        for user in @users when user.owner
          return user.username


  _ruleChecker: (rules) ->

    for user in @users when user.id is globals.userId
      for rule in rules
        return no  unless user[rule]
      return yes

    return no


  setApproved: ->
    for user in @users when user.id is globals.userId
      user.approved = yes


  isMine      : -> @_ruleChecker ['owner']
  isApproved  : -> @isMine() or @_ruleChecker ['approved']
  isPermanent : -> @_ruleChecker ['permanent']
  isManaged   : -> @provider is 'managed'
  isRunning   : -> @status?.state is JMachine.State.Running
  isStopped   : -> @status?.state is JMachine.State.Stopped
  isBuilt     : -> @status?.state isnt JMachine.State.NotInitialized
  isUsable    : -> @isRunning() or @isStopped()
  getOldOwner : -> @getAt 'meta.oldOwner'
  isAlwaysOn  : -> @getAt 'meta.alwaysOn'

  getStackId  : ->
    @_stackId ? kd.singletons.computeController.findStackFromMachineId @getId()

  getChannelId: -> @getAt 'channelId'
  setChannelId: (options, callback) ->
    debug 'setChannelId', options
    { storage } = kd.singletons.computeController

    super options, (err, machine) ->
      return callback err  if err

      storage.machines.push machine

      unless options.channelId
        delete (storage.machines.get '_id', machine._id).channelId

      callback err, machine

  getStatus: -> @getAt 'status.state'


  getSharedUsers: ->

    @getAt('users')
      .filter (user) -> user.instance? and user.instance.profile.nickname isnt nick()
      .map (user) -> user.instance


  reviveUsers: (options, callback = kd.noop) ->

    { storage } = kd.singletons.computeController

    super options, (err, accounts = []) =>
      return callback err  if err

      debug 'reviveUsers', { accounts, machine: this }

      machineUsers = @getAt 'users'

      accounts.forEach (account) ->
        machineUser = _.find machineUsers, (user) ->
          user.username is account.profile.nickname

        if machineUser
        then machineUser.instance = account
        else machineUsers.push {
          username: account.profile.nickname
          instance: account
          permanent: yes
        }

      @setAt 'users', machineUsers

      storage.machines.push this

      callback null, accounts


  setLabel: (label, callback) ->

    { storage } = kd.singletons.computeController

    super label, (err, newLabel) =>
      return callback err  if err

      @setAt 'label', newLabel

      storage.machines.push this

      return callback err, newLabel


  deny: (callback) ->

    debug 'deny called'
    { storage } = kd.singletons.computeController

    super (err) =>
      return callback err  if err

      storage.machines.pop this
      callback null


  approve: (callback) ->

    debug 'approve called'
    { storage } = kd.singletons.computeController

    super (err) =>
      return callback err  if err

      @setApproved()
      storage.machines.push this
      callback null


  getType: ->

    { Own, Shared, Reassigned, Collaboration } = JMachine.Type

    switch
      when @isPermanent() then Shared
      when @getOldOwner() then Reassigned
      when @isMine()      then Own
      else Collaboration


  getTitle: ->

    { Shared, Reassigned, Collaboration } = JMachine.Type

    switch @getType()
      when Shared, Collaboration then "#{@label} (@#{@getOwner()})"
      when Reassigned then "#{@label} (@#{@getOldOwner()})"
      else @label


  unshareAllUsers: ->

    debug 'unshare all users'

    Promise.all @getSharedUsers().map (user) =>
      @unshareUser user.profile.nickname


  unshareUser: (username) ->

    debug 'unshare user', username

    { storage } = kd.singletons.computeController

    new Promise (resolve, reject) =>
      remote.api.SharedMachine.kick @uid, [username], (err) =>
        promise = @getBaseKite()
          .klientUnshare { username, permanent: yes }
          .then => @users = @users.filter (user) -> user.username isnt username
          .then => @reviveUsers { permanentOnly : yes }
          .then ->
            if err then reject new Error err else resolve()
          .catch reject


  shareUser: (username) ->

    debug 'share user', username

    new Promise (resolve, reject) =>
      remote.api.SharedMachine.add @uid, [username], (err) =>
        return reject new Error err  if err

        @getBaseKite()
          .klientShare { username, permanent: yes }
          .then => @users.push { approved: no, permanent: yes, username, owner: no }
          .then => @reviveUsers { permanentOnly : yes }
          .then resolve
          .catch reject
