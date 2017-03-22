{ Base, secure, signature } = require 'bongo'

google       = require 'googleapis'
google_utils = require 'koding-googleapis'
KodingError  = require '../error'

{ notifyByUsernames } = require './notify'

JMachine   = require './computeproviders/machine'


module.exports = class Collaboration extends Base
  @share()

  @set
    sharedMethods :
      static      :
        stop      : (signature String, String, Function)
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


  unshareMachine = (channelId, callback) ->

    JMachine.one { channelId }, (err, machine) ->
      owner = null

      for user in machine.users when user.sudo and user.owner
        owner = user
        break

      machine.update { $set: { users: [owner] } }, callback


  @stop = secure authenticated (client, fileId, channelId, callback) ->

    getRealtimeDocument fileId, (err, doc) ->

      return callback err  if err
      return callback 'root document is not found'  unless doc

      unless doc?.data?.value?.pingTime?
        return callback 'ping time is not found'

      lastSeen = new Date parseInt doc.data.value.pingTime.value, 10

      { timeout } = KONFIG.collaboration

      if (Date.now() - lastSeen.getTime()) > timeout
      then unshareMachine channelId, callback
      else callback 'host is alive'


  @add = secure (client, channelId, target, callback) ->

    asUser  = yes
    options = { target, asUser }
    setUsers client, channelId, options, (err, machine) ->
      return callback err  if err

      data = { channelId, group: client?.context?.group }
      notifyByUsernames options.target, 'CollaborationInvitation', data

      callback null, machine


  @kick = secure (client, channelId, target, callback) ->

    options = { target, asUser: no }
    setUsers client, channelId, options, (err, machine) ->
      return callback err  if err
      callback null, machine


  setUsers = (client, channelId, options, callback) ->

    options.permanent = no
    JMachine.one { channelId }, (err, machine) ->

      return callback err  if err
      return callback new KodingError 'Machine not found'  unless machine

      machine.shareWith$ client, options, (err) ->
        return callback err  if err
        JMachine.one { _id: machine._id }, callback
