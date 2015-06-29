_       = require 'lodash'
Nuclear = require 'nuclear-js'

module.exports = class KodingFluxReactor extends Nuclear.Reactor

  ###*
   * Extend Neclear.Reactor::registerStores to accept classes rather than
   * singleton stores.
   *
   * @param {object<string, KodingFluxStore::constructor>} storeClasses
  ###
  registerStores: (storeClasses) ->

    stores = _.mapValues storeClasses, (StoreClass) => new StoreClass

    # we injected reactor instance to our stores,
    # leave the rest to Nuclear.
    super stores


