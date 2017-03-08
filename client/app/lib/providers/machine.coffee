debug                 = (require 'debug') 'machine'
Promise               = require 'bluebird'
_                     = require 'lodash'
kd                    = require 'kd'
KDObject              = kd.Object
doesQueryStringValid  = require '../util/doesQueryStringValid'
nick                  = require '../util/nick'
globals               = require 'globals'
runMiddlewares        = require 'app/util/runMiddlewares'
TestMachineMiddleware = require './middlewares/testmachine'


module.exports = class Machine extends KDObject

  @getMiddlewares = ->
    return [
      TestMachineMiddleware.Machine
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


  constructor: (options = {}) ->

    { machine } = options
    unless machine?.bongo_?.constructorName is 'JMachine'
      kd.error 'Data should be a JMachine instance'

    delete options.machine

    super options, machine

    @jMachine = @getData()
    @updateLocalData()

    @fs =
      create: (options = {}, callback) =>
        options.machine = this
        require('../util/fs/fsitem').create options, callback

    { computeController } = kd.singletons

    computeController.on "public-#{machine._id}", (event) =>

      unless event.status is @jMachine.status.state

        @jMachine.setAt? 'status.state', event.status
        @updateLocalData()

    computeController.on "revive-#{machine._id}", (machine) =>

      if machine?
        # update machine data
        @jMachine = machine
        @updateLocalData()
      else
        @status = { state: Machine.State.Terminated }
        @queryString = null
        # FIXMERESET ~ GG
        # computeController.reset yes

    @jMachine.on? 'update', =>

      { reactor } = kd.singletons
      actions     = require 'app/flux/environment/actiontypes'
      reactor.dispatch actions.MACHINE_UPDATED, {
        id: @_id, machine: @jMachine
      }

      @updateLocalData()

    @fetchInfo => @emit 'ready'


  updateLocalData: ->

    { @label, @ipAddress, @_id, @provisioners, @provider, @credential
      @status, @uid, @domain, @queryString, @slug } = @jMachine
    @alwaysOn = @jMachine.meta.alwaysOn ? no

    @readyState = 0
    @fetchInfo()



  setLabel: (label, callback) ->

    { computeController } = kd.singletons

    @jMachine.setLabel label, (err, newSlug) =>

      unless err?
        computeController.triggerReviveFor this._id
        computeController.emit 'MachineDataModified'

      callback err, newSlug


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

      kontrol.getKite { name: 'klient', @queryString, correlationName: @uid }

    else

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
        kite.klientInfo().then (info) ->
          kallback info
        .timeout globals.COMPUTECONTROLLER_TIMEOUT
        .catch (err) ->
          kd.warn '[Machine][fetchInfo] Failed to get klient.info', err
          kallback()
    else
      kallback()


  getOwner: ->

    switch @provider
      when 'managed'
        return @data.credential
      else # Use users array for other types of providers ~ GG
        for user in @jMachine.users when user.owner
          return user.username


  _ruleChecker: (rules) ->

    for user in @jMachine.users when user.id is globals.userId
      for rule in rules
        return no  unless user[rule]
      return yes

    return no


  isMine      : -> @_ruleChecker ['owner']
  isApproved  : -> @isMine() or @_ruleChecker ['approved']
  isPermanent : -> @_ruleChecker ['permanent']
  isManaged   : -> @provider is 'managed'
  isRunning   : -> @status?.state is Machine.State.Running
  isStopped   : -> @status?.state is Machine.State.Stopped
  isBuilt     : -> @status?.state isnt Machine.State.NotInitialized
  isUsable    : -> @isRunning() or @isStopped()
  getOldOwner : -> @jMachine.meta.oldOwner

  getChannelID: ->
    debug 'getChannelID requested'
    return null
