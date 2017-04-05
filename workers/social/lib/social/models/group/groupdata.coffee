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
        fetchByKey: [
          (signature String, Function)
        ]

  @create = (slug, callback) ->
    data = new JGroupData { slug }
    data.save (err) ->
      return callback err  if err
      callback null, data

  # fetchByKey fetches given path from GroupData if only they are available
  # within the group.
  #
  # @param {String} path
  #   Provide the path you would like to fetch.
  #
  # @return {Object} persisted value.
  @fetchByKey = secure (client, path, callback) ->
    # for more granular control, specify each sub key as well.
    availableKeys = [ 'countly' ]

    if availableKeys.indexOf(path) is -1
      return callback new Error 'path is forbidden'

    slug = client.context.group
    JGroupData.fetchDataAt slug, path, callback

  @fetchData: (slug, callback) ->
    return callback new Error 'slug is required' unless slug

    JGroupData.one { slug }, (err, data) ->
      return callback err  if err
      return callback null, data if data

      JGroupData.create slug, callback

  @fetchDataAt: (slug, path, callback) ->
    return callback new Error 'slug is required' unless slug

    opts = {}
    opts[path] = 1 if path

    JGroupData.one { slug }, opts, (err, data) ->
      return callback err  if err

      return callback null, getAt data.payload, path

  # see docs on JGroup::modifyData
  modifyData : (slug, data, callback) ->
    return callback new Error 'slug is required' unless slug

    # it's only allowed to change followings
    whitelist  = ['github.organizationToken' ]

    # handle $set and $unset cases in one
    operation  = { $set: {}, $unset: {} }
    for item in whitelist
      key = "payload.#{item}"
      if data[item]?
      then operation.$set[key]   = data[item]
      else operation.$unset[key] = data[item]

    JGroupData.fetchData slug, (err, data) ->
      return callback err  if err

      data.update operation, (err) ->
        callback err
