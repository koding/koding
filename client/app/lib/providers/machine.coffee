Promise = require 'bluebird'
kd = require 'kd'
KDObject = kd.Object
doesQueryStringValid = require '../util/doesQueryStringValid'
nick = require '../util/nick'
globals = require 'globals'


module.exports = class Machine extends KDObject

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
    'Pending'         # Machine is being resized by provisioner
    'Unknown'         # Machine is in an unknown state
                      # needs to be resolved manually
  }


  constructor: (options = {})->

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

    {computeController} = kd.singletons

    computeController.on "public-#{machine._id}", (event)=>

      unless event.status is @jMachine.status.state

        @jMachine.setAt? "status.state", event.status
        @updateLocalData()

    computeController.on "revive-#{machine._id}", (machine)=>

      if machine?
        # update machine data
        @jMachine = machine
        @updateLocalData()
      else
        @status = state: Machine.State.Terminated
        @queryString = null
        computeController.reset yes


  updateLocalData:->
    { @label, @ipAddress, @_id, @provisioners, @provider
      @status, @uid, @domain, @queryString, @slug } = @jMachine
    @alwaysOn = @jMachine.meta.alwaysOn ? no


  setLabel:(label, callback)->

    {computeController} = kd.singletons

    @jMachine.setLabel label, (err, newSlug)=>

      unless err?
        computeController.triggerReviveFor this._id
        computeController.emit 'MachineDataModified'

      callback err, newSlug


  getName: ->

    {uid, label, ipAddress} = this

    return label or ipAddress or uid or "one of #{nick()}'s machines"


  getBaseKite: (createIfNotExists = yes)->

    { kontrol } = kd.singletons

    klient = kontrol.kites?.klient?[@uid]
    return klient  if klient

    if createIfNotExists and doesQueryStringValid @queryString

      kontrol.getKite { name: "klient", @queryString, correlationName: @uid }

    else

      {
        init       : -> Promise.reject()
        connect    : kd.noop
        disconnect : kd.noop
      }


  getOwner: ->

    switch @provider
      when 'koding', 'managed'
        return @data.credential


  _ruleChecker: (rules) ->

    for user in @jMachine.users
      if user.id is globals.userId
        for rule in rules
          return no  unless user[rule]
        return yes

    return no


  isMine      : -> @_ruleChecker ['owner', 'sudo']
  isApproved  : -> @isMine() or @_ruleChecker ['approved']
  isPermanent : -> @_ruleChecker ['permanent']
  isManaged   : -> @provider is 'managed'
