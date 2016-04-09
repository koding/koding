kd = require 'kd'
React = require 'kd-react'
ReactView = require 'app/react/reactview'
CreditCard = require './components/creditcard'

module.exports = class HomeTeamBillingCreditCard extends ReactView

  renderReact: -> <CreditCard />


