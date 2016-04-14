{ createModule } = require 'nuclear-module'

module.exports = createModule 'Payment',
  stores:
    PaymentValuesStore: require './stores/paymentvaluesstore'
  actions: require './actions'
  getters: require './getters'
