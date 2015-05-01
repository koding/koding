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

  ###*
   * Verify that the given snapshot will fit within the given storage.
   *
   * @param {Object} options
   * @param {String} options.snapshotId - The snapshot to verify
   * @param {Number} options.storage - The storage size to verify that
   *   this snapshot will fit into.
  ###
  @verifySnapshot = (client, options, callback) ->

    {delegate} = client.connection
    {storage, snapshotId} = options

    unless snapshotId
      return callback new KodingError 'snapshotId is not provided'

    @one$ client, snapshotId, (err, snapshot) ->

      return callback err  if err
      return callback new KodingError 'No such snapshot'  unless snapshot

      if +(snapshot.storageSize) > storage
        return callback new KodingError \
          'Storage size is not enough for this snapshot', 'SizeError'

      callback null, snapshot


  # Static Methods
  # ---------------

  ###*
   * Perform a FindOne() query on the jSnapshots selection, for this
   * user's originId only.
   *
   * @param {String} snapshotId The snapshotId to query for.
   * @param {Function(err:Error)} callback
  ###
  @one$ = permit 'list snapshots',

    success: (client, snapshotId, callback) ->

      {delegate} = client.connection

      selector     =
        originId   : delegate.getId()
        snapshotId : snapshotId

      @one selector, callback


  ###*
   * Perform a Find() query on the jSnapshots collection, for this user's
   * originId only.
   *
   * @param {Object} selector The mongodb selector to query with
   * @param {Object} options The mongodb query options. Limit, sort, etc.
   * @param {Function(err:Error)} callback
  ###
  @some$ = permit 'list snapshots',

    success: (client, selector, options, callback) ->

      {delegate} = client.connection
      selector  ?= {}

      # Ensure that a user can only list their own snapshots
      selector.originId = delegate.getId()

      @some selector, options, callback


  # Instance Methods
  # ---------------

  ###*
   * Rename the snapshot instance with the given label.
   *
   * @param {String} label The new label (name).
   * @param {Function(err: Error)} callback
  ###
  rename: permit 'update snapshot',

    success: (client, label, callback) ->

      if not label or label is ''
        return callback new KodingError 'JSnapshot.rename: label is empty'

      {delegate} = client.connection

      unless delegate.getId().equals @originId
        return callback new KodingError 'Access denied'

      @update $set: {label}, (err) ->
        callback err
