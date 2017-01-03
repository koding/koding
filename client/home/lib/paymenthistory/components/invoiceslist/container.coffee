{ connect } = require 'react-redux'
{ all: allInvoices } = require 'app/redux/modules/payment/invoices'

View = require './view'

mapState = (state) ->
  return {
    invoices: allInvoices(state)
  }

module.exports = connect(
  mapState
)(View)
