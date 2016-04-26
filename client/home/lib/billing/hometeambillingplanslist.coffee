kd = require 'kd'
React = require 'kd-react'
ReactView = require 'app/react/reactview'
PlansList = require './components/planslist'

module.exports = class HomeTeamBillingCreditCard extends ReactView

  constructor: (options = {}, data) ->

    options.cssClass = 'HomeAppView--section HomeTeamBillingPlansList'

    super options, data


  renderReact: -> <PlansList.Container />



