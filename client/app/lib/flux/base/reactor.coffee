_       = require 'lodash'
Nuclear = require 'nuclear-js'

module.exports = class KodingFluxReactor extends Nuclear.Reactor

  ###*
   * Extend Nuclear.Reactor::registerStores to accept classes rather than
   * singleton stores.
   *
   * @param {object<string, KodingFluxStore::constructor>} storeClasses
  ###
  registerStores: (storeClasses) ->

    if Array.isArray storeClasses
      storeClasses = mapWithClassName storeClasses

    stores = _.mapValues storeClasses, (StoreClass) ->
      if 'function' is typeof StoreClass
      then new StoreClass
      else StoreClass
    # we injected reactor instance to our stores,
    # leave the rest to Nuclear.
    super stores


###*
 * Turns given store classes array into an object with keys as given class's
 * name.
 *
 * @param {Array<KodingFluxStore::constructor>} classes
 * @return {object<string, KodingFluxStore::constructor>} storeClasses
###
mapWithClassName = (classes) ->

  return classes.reduce (result, klass) ->
    result[klass.getterPath] = klass
    return result
  , {}
