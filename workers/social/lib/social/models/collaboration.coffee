{ Base, secure, signature } = require 'bongo'

google       = require 'googleapis'
google_utils = require 'koding-googleapis'

{ notifyByUsernames } = require './notify'

JMachine   = require './computeproviders/machine'
JWorkspace = require './workspace'


module.exports = class Collaboration extends Base
  @share()

  @set
    sharedMethods :
      static      :
        stop      : (signature String, Object, Function)
        add       : (signature String, Object, Function)
        kick      : (signature String, Object, Function)


  drive = null


  getRealtimeDocument = (fileId, callback) ->

    return callback 'drive is not ready'  unless drive

    drive.realtime.get { fileId }, callback


  authenticated = (method) ->

    options =
      authorization_options  : { subject: 'https://www.googleapis.com/auth/drive' }
      authentication_handler : (auth) -> drive = google.drive { version: 'v2', auth }

    return google_utils.authenticated options, method


  unshareMachine = (workspace, callback) ->
    uid = workspace.machineUId

    JMachine.one { uid }, (err, machine) ->
      owner = null

      for user in machine.users when user.sudo and user.owner
        owner = user
        break

      machine.update { $set: { users: [owner] } }, callback


  @stop = secure authenticated (client, fileId, workspace, callback) ->

    getRealtimeDocument fileId, (err, doc) ->

      return callback err  if err
      return callback 'root document is not found'  unless doc

      unless doc?.data?.value?.pingTime?
        return callback 'ping time is not found'

      lastSeen = new Date parseInt doc.data.value.pingTime.value, 10

      { timeout } = KONFIG.collaboration

      if (Date.now() - lastSeen.getTime()) > timeout
      then unshareMachine workspace, callback
      else callback 'host is alive'


  @add = secure (client, workspaceId, target, callback) ->

    asUser  = yes
    options = { target, asUser }
    setUsers client, workspaceId, options, (err, machine) ->
      return callback err  if err

      machineUId = machine.uid
      data =  { machineUId, workspaceId }

      notifyByUsernames options.target, 'CollaborationInvitation', data

      callback()


  @kick = secure (client, workspaceId, target, callback) ->

    asUser  = no
    options = { target, asUser }
    setUsers client, workspaceId, options, callback


  setUsers = (client, workspaceId, options, callback) ->

    JWorkspace.one { _id: workspaceId }, (err, workspace) ->

      return callback err  if err
      return callback 'Workspace is not found'  unless workspace

      options.permanent = no
      JMachine.shareByUId client, workspace.machineUId, options, callback
