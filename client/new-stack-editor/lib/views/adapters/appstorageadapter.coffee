kd = require 'kd'

module.exports = class AppStorageAdapter

  constructor: ->
    @as = kd.singletons.appStorageController.storage 'StackEditorLayout'

  get: (identifier, callback) ->
    callback @as.getValue('layout')?[identifier]

  store: (storage, callback) ->
    callback @as.setValue 'layout', storage
