kd = require 'kd'
React = require 'kd-react'
KDReactorMixin = require 'app/flux/base/reactormixin'
PaymentFlux = require 'app/flux/payment'
CreditCardView = require './view'


module.exports = class CreditCardContainer extends React.Component

  componentWillMount: ->

    { actions } = PaymentFlux kd.singletons.reactor

    actions.loadGroupCreditCard()


  render: ->

    <CreditCardView
      formValues={}
      card={@state.paymentValues.get 'groupCreditCard'} />
