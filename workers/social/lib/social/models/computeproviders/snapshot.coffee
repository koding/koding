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
      'update snapshot' : ['member']

    schema              :
      originId          : ObjectId
      machineId         : ObjectId
      snapshotId        : String
      region            : String
      createdAt         : Date
      storageSize       : String
      label             : String


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

  rename: permit 'update snapshot',

    success: (client, label, callback) ->

      if not label or label is ''
        return callback new KodingError 'JSnapshot.rename: label is empty'

      {delegate} = client.connection

      unless delegate.getId().equals @originId
        return callback new KodingError 'Access denied'

      @update $set: {label}, (err) ->
        callback err
