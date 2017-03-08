async = require 'async'
bongo = require 'bongo'
{ secure, signature } = bongo

JMachine   = require './computeproviders/machine'

SocialChannel = require './socialapi/channel'

KodingError = require '../error'

module.exports = class Sidebar extends bongo.Base

  { revive } = require './computeproviders/computeutils'

  @share()

  @set
    sharedMethods        :
      static             :
        fetchEnvironment : (signature Function)


  @fetchEnvironment = secure revive

    shouldReviveClient   : yes
    shouldReviveProvider : no
    hasOptions           : no

  , (client, callback) ->

    data            =
      collaboration : []
      shared        : []
      own           : []

    { r: { user, group } } = client

    query =
      'users.id'  : user.getId()
      'groups.id' : group.getId()

    JMachine.some query, {}, (err, machines) ->
      return callback new KodingError err  if err

      machineUIds = machines.map (machine) -> machine.uid

      options = { client, user, machines, callback }
      options.addOwnFn = makeEnvironmentNodeAdderFn data.own
      options.addSharedFn = makeEnvironmentNodeAdderFn data.shared
      options.addCollaborationFn = makeEnvironmentNodeAdderFn data.collaboration
      options.callback = -> callback null, data

      decorateEnvironmentData options


  makeEnvironmentNodeAdderFn = (list) ->

    findNode = (machine) ->

      for node in list
        if machine.uid is node.machine.uid
          return node

    return ({ machine }) ->

      unless node = findNode machine
        node = { machine }
        list.push node


  decorateEnvironmentData = (options) ->

    { client, user } = options
    { machines } = options
    { addOwnFn, addSharedFn, addCollaborationFn } = options
    { callback } = options

    machineMap = {}

    machines.forEach (machine) ->
      machineMap[machine.uid] = machine

      addNodeFn = switch
        when isMachineOwner user, machine
          addOwnFn
        when isMachineShared user, machine
          addSharedFn

      addNodeFn? { machine }

    callback()


  isMachineOwner = (user, machine) ->

    for u in machine.users
      if u.owner and u.id.equals user.getId()
        return yes

    return no


  isMachineShared = (user, machine) ->

    for u in machine.users
      if (u.id.equals user.getId()) and u.permanent
        return yes

    return no
