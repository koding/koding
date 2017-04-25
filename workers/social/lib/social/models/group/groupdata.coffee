{ secure, signature, Model, JsPath:{ getAt } } = require 'bongo'

module.exports = class JGroupData extends Model
  JPermissionSet = require './permissionset'
  { permit }     = JPermissionSet

  @share()

  @set
    indexes       :
      slug        : 'unique'

    sharedEvents  :
      static      : []
      instance    : []

    schema        :
      slug        :
        type      : String
        validate  : require('../name').validateName
        set       : (value) -> value.toLowerCase()
      payload     : Object

    sharedMethods :
      static      :
        fetchByKey: (signature String, Function)


  @create = (slug, callback) ->
    data = new JGroupData { slug }
    data.save (err) ->
      # this happens if socialapi creates the document in between fetch/create
      # operations.
      if err?.code is 11000 # duplicate key error
        return JGroupData.fetchData slug, callback

      return callback err  if err
      callback null, data


  @fetchData = (slug, callback) ->
    return callback new Error 'slug is required'  unless slug

    JGroupData.one { slug }, (err, data) ->
      return callback err  if err
      return callback null, data if data

      JGroupData.create slug, callback

  # fetchByKey fetches given path from GroupData if only they are available
  # within the group.
  #
  # @param {String} path
  #   Provide the path you would like to fetch.
  #
  # @return {Object} persisted value.
  @fetchByKey = permit 'open group',
    success: (client, path, callback) ->
      # for more granular control, specify each sub key as well.
      availableKeys = [ 'countly' ]

      unless path in availableKeys
        return callback new Error 'path is forbidden'

      slug = client?.context?.group
      JGroupData.fetchDataAt slug, path, callback


  @fetchDataAt = (slug, path, callback) ->
    return callback new Error 'slug is required'  unless slug

    opts = {}
    opts["payload.#{path}"] = 1 if path

    JGroupData.one { slug }, opts, (err, data) ->
      return callback err  if err

      payload = if data then getAt data.payload, path else null
      return callback null, payload


  # see docs on JGroup::modifyData
  @modifyData = (slug, data, callback) ->
    return callback new Error 'slug is required'  unless slug

    # it's only allowed to change followings
    allowedPaths = [ 'github.organizationToken', 'test_key__' ]

    # handle $set and $unset cases in one
    operation = {}

    allowedPaths.forEach (path) ->
      key = "payload.#{path}"
      if val = data[path]
        operation.$set ?= {}
        operation.$set[key] = val
      else
        operation.$unset ?= {}
        operation.$unset[key] = ''

    JGroupData.fetchData slug, (err, data) ->
      return callback err  if err

      data.update operation, (err) ->
        callback err
