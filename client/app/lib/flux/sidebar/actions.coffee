kd = require 'kd'
actionTypes = require './actiontypes'

loadVisibilityFilters = ->

  { reactor, appStorageController } = kd.singletons

  return new Promise (resolve) ->
    reactor.dispatch actionTypes.LOAD_SIDEBAR_ITEM_VISIBILITIES_BEGIN

    storage = appStorageController.storage('Sidebar')

    storage.fetchValue 'visibility', (visibilityFilters) ->
      reactor.dispatch actionTypes.LOAD_SIDEBAR_ITEM_VISIBILITIES_SUCCESS, {
        visibilityFilters
      }
      resolve()


makeVisible = (type, id) ->

  { reactor, appStorageController } = kd.singletons

  return new Promise (resolve, reject) ->
    reactor.dispatch actionTypes.MAKE_SIDEBAR_ITEM_VISIBLE_BEGIN, { type, id }

    storage = appStorageController.storage('Sidebar')

    storage.fetchValue 'visibility', (visibilityFilters) ->
      visibilityFilters = withDefaults visibilityFilters  unless visibilityFilters
      visibilityFilters[type][id] = 'visible'
      storage.setValue 'visibility', visibilityFilters, ->
        reactor.dispatch actionTypes.MAKE_SIDEBAR_ITEM_VISIBLE_SUCCESS, { type, id }


makeHidden = (type, id) ->

  { reactor, appStorageController } = kd.singletons

  return new Promise (resolve, reject) ->
    reactor.dispatch actionTypes.MAKE_SIDEBAR_ITEM_HIDDEN_BEGIN, { type, id }

    storage = appStorageController.storage('Sidebar')

    storage.fetchValue 'visibility', (visibilityFilters) ->
      visibilityFilters = withDefaults visibilityFilters  unless visibilityFilters
      visibilityFilters[type][id] = 'hidden'
      storage.setValue 'visibility', visibilityFilters, ->
        reactor.dispatch actionTypes.MAKE_SIDEBAR_ITEM_HIDDEN_SUCCESS, { type, id }


saveVisible = (storage, type, id, callback) ->

  visibilityFilters = storage.getValue 'visibility'
  visibilityFilters[type][id] = 'visible'
  storage.setValue 'visibility', visibilityFilters, callback


saveHidden = (storage, type, id, callback) ->

  visibilityFilters = storage.getValue 'visibility'
  visibilityFilters[type][id] = 'hidden'
  storage.setValue 'visibility', visibilityFilters, callback


withDefaults = (visibilityFilters) -> visibilityFilters or { stack: {}, draft: {} }



module.exports = {
  loadVisibilityFilters
  makeVisible
  makeHidden
}
