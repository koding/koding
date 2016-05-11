kd = require 'kd'
React = require 'kd-react'
KDReactorMixin = require 'app/flux/base/reactormixin'
PaymentFlux = require 'app/flux/payment'
InvoicesList = require './view'


module.exports = class InvoicesListContainer extends React.Component

  getDataBindings: ->
    return {
      paymentValues: PaymentFlux.getters.paymentValues
    }


  render: ->
    invoices = @state.paymentValues.get 'groupInvoices'

    <InvoicesList invoices={invoices} />


InvoicesListContainer.include [KDReactorMixin]
