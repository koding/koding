kd = require 'kd'
React = require 'kd-react'
ReactView = require 'app/react/reactview'
Subscription = require 'component-lab/Subscription'

module.exports = class HomeTeamBillingCreditCard extends ReactView

  constructor: (options = {}, data) ->

    options.cssClass = 'HomeAppView--section HomeTeamBillingPlansList'

    super options, data


  renderReact: -> <Subscription />
