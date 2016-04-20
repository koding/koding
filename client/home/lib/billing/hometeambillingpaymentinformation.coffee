kd        = require 'kd'
React = require 'kd-react'
ReactView = require 'app/react/reactview'
PaymentInformation = require './components/paymentinformation'

module.exports = class HomeTeamBillingForm extends ReactView

  constructor: (options = {}, data) ->

    options.cssClass = 'HomeTeamBillingForm'

    super options, data


  renderReact: -> <PaymentInformation />

