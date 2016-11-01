kd = require 'kd'
React = require 'app/react'
ReactView = require 'app/react/reactview'
CreditCard = require './components/creditcard'

module.exports = class HomeTeamBillingCreditCard extends ReactView

  constructor: (options = {}, data) ->

    options.cssClass = 'HomeTeamBillingCreditCard'

    super options, data


  renderReact: -> <CreditCard.Container />


