{ createModule } = require 'nuclear-module'

module.exports = createModule 'Payment',
  stores:
    PaymentValuesStore: require './stores/paymentvaluesstore'
    GroupPlansStore: require './stores/groupplansstore'
  actions: require './actions'
  getters: require './getters'
