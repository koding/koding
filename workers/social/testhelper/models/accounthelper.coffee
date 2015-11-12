JAppStorage      = require '../../lib/social/models/appstorage'
{ Relationship } = require 'jraphical'

createOldAppStorageDocument = (data, callback) ->
  { account, appId, version, bucket } = data
  bucket ?= {}

  storage = new JAppStorage { appId, version, bucket }
  storage._shouldPrune = no
  storage.save (err) ->
    return callback err  if err

    relationshipOptions =
      targetId    : storage.getId()
      targetName  : 'JAppStorage'
      sourceId    : account.getId()
      sourceName  : 'JAccount'
      as          : 'appStorage'
      data        : { appId, version }

    rel = new Relationship relationshipOptions
    rel.save (err) ->
      callback err, { storage, relationshipOptions }


module.exports = {
  createOldAppStorageDocument
}
