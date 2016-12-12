kd = require 'kd'

module.exports = class LocalStorageAdapter

  constructor: ->
    @ls = kd.singletons.localStorageController.storage 'StackEditorLayout'

  get: (identifier, callback) ->
    callback @ls.getValue('layout')?[identifier]

  store: (storage, callback) ->
    callback @ls.setValue 'layout', storage
