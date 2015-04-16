{ Module }  = require 'jraphical'
{ revive }  = require './computeutils'
KodingError = require '../../error'

{argv}      = require 'optimist'
KONFIG      = require('koding-config-manager').load("main.#{argv.c}")


module.exports = class JSnapshot extends Module

  { ObjectId, signature, daisy, secure } = require 'bongo'

  @trait __dirname, '../../traits/protected'

  {permit}  = require '../group/permissionset'

  @share()

  @set

    indexes             :
      snapshotId        : 'sparse'

    sharedEvents        :
      static            : [ ]
      instance          : [ ]

    sharedMethods       :
      static            :
        one             :
          (signature String, Function)
        some            :
          (signature Object, Object, Function)
      instance          :
        rename          :
          (signature String, Function)

    permissions         :
      'list snapshots'  : ['member']
      'save snapshot'   : ['member']

    schema              :
      originId          : ObjectId
      machineId         : ObjectId
      snapshotId        : String
      region            : String
      createdAt         : Date
      storageSize       : String


  # Private Methods
  # ---------------

  # Static Methods
  # ---------------

  @one$ = permit 'list snapshots',

    success: (client, snapshotId, callback) ->

      {delegate} = client.connection

      selector     =
        originId   : delegate.getId()
        snapshotId : snapshotId

      @one selector, callback


  @some$ = permit 'list snapshots',

    success: (client, selector, options, callback) ->

      {delegate} = client.connection
      selector  ?= {}

      # Ensure that a user can only list their own snapshots
      selector.originId = delegate.getId()

      @some selector, options, callback


  # Instance Methods
  # ---------------

  rename: permit 'save snapshot',
    success: (client, newName, callback) ->
      return callback new Error "JSnapshot.rename: Disabled. No Kloud support for name"
      if newName == ""
        return callback new Error "JSnapshot.rename: newName empty"
      @update name: newName
      @save callback

