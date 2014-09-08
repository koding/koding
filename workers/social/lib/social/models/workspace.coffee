{ Model }  = require 'bongo'
{ Module } = require 'jraphical'

module.exports = class JWorkspace extends Module

  {signature, secure} = require 'bongo'
  @share()

  @set
    schema            :
      name            : String
      machineUId      : String
      rootPath        : String
      owner           : String
      layout          : Object

    sharedMethods  :
      static       :
        create     : signature Object, Function
        some       : signature Object, Object, Function
      instance     : []
    sharedEvents   :
      static       : []
      instance     : []

  @create = secure (client, data, callback) ->
    data.owner = client.connection.delegate.profile.nickname
    workspace  = new JWorkspace data

    workspace.save (err) ->
      return callback err  if err
      return callback null, workspace

  some$: secure (client, query = {}, callback) ->
    query.owner = client.connection.delegate.profile.nickname
    JWorkspace.some query, callback
