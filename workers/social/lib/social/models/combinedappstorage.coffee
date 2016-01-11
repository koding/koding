JStorage    = require './storage'
KodingError = require '../error'

module.exports = class JCombinedAppStorage extends JStorage

  { signature, ObjectId } = require 'bongo'

  @share()

  @set
    indexes         :
      accountId     : 'unique'
    sharedEvents    :
      static        : []
      instance      : []
    sharedMethods   :
      static        : {}
      instance      :
        upsert:
          (signature String, Object, Function)
    schema          :
      accountId     : ObjectId
      bucket        :
        type        : Object
        default     : -> {}


  upsert: (appId, options, callback) ->

    unless appId
      return callback new KodingError 'appId is not set!'

    options.accountId = @getAt 'accountId'
    JCombinedAppStorage.upsert appId, options, (err, storage) ->
      return callback err, storage


  @upsert: (appId, options, callback) ->

    { accountId, query, data } = options

    unless appId and accountId
      return callback new KodingError 'appId and accountId is not set!'

    selector  = { accountId }
    options   = { upsert : yes }

    # if query is not set, create a default one
    unless query
      query = { $set : {} }
      query.$set["bucket.#{appId}.data"] = data ? {}

    # to prevent setting accountId on each call
    query.$setOnInsert ?= {}
    query.$setOnInsert.accountId = accountId

    JCombinedAppStorage.update selector, query, options, (err) ->
      return callback err  if err

      JCombinedAppStorage.one { accountId }, (err, storage) ->
        return callback err, storage
