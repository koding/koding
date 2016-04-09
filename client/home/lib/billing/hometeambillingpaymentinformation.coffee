kd        = require 'kd'
React = require 'kd-react'
ReactView = require 'app/react/reactview'
PaymentInformation = require './components/paymentinformation'

module.exports = class HomeTeamBillingForm extends ReactView

  renderReact: -> <PaymentInformation />

