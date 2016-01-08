{ Model } = require 'bongo'

module.exports = class JCustomPartials extends Model

  { signature, secure } = require 'bongo'
  @share()

  @set
    indexes           :
      partialType     : 'sparse'
    schema            :
      name            : String
      partialType     : String
      partial         : Object
      isActive        : Boolean
      isPreview       : Boolean
      previewInstance : String
      viewInstance    : String
      createdAt       :
        type          : Date
        default       : -> new Date
      publishedAt     : Date

    sharedMethods :
      static      :
        create    : [
          (signature Object, Function)
          (signature Object, Object, Function)
        ]
        some      :
          (signature Object, Object, Function)
      instance     :
        update     : [
          (signature Object, Function)
          (signature Object, Object, Function)
        ]
        remove     : [
          (signature Function)
          (signature Object, Function)
        ]
    sharedEvents    :
      static        : []
      instance      : []

  @create = secure (client, data, callback) ->
    checkPermission client, (err, res) ->
      return callback err if err
      customPartial = new JCustomPartials data
      customPartial.save (err) ->
        return callback err if err
        return callback null, customPartial

  checkPermission: checkPermission = (client, callback) ->
    { context:{ group } } = client
    JGroup = require './group'
    JGroup.one { slug:group }, (err, group) ->
      return callback err if err
      return callback new Error 'group not found' unless group
      group.canEditGroup client, (err, hasPermission) ->
        return callback err if err
        return callback new Error 'Can not edit group' unless hasPermission
        return callback null, yes

  update$: secure (client, data, callback) ->
    @checkPermission client, (err, res) =>
      return callback err if err

      isPublished      = data.isActive and not @isActive
      data.publishedAt = new Date()  if isPublished

      @update { $set:data }, callback

  remove$: secure (client, callback) ->
    @checkPermission client, (err, res) =>
      return callback err if err
      @remove callback
