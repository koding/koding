React = require 'app/react'
ReactView = require 'app/react/reactview'
PlanDeactivation = require './components/plandeactivation'

module.exports = class HomeSupportPlanDeactivation extends ReactView

  constructor: (options = {}, data) ->

    super options, data

  getActivePlan: ->

    return 'basic'

  deactivateSupportPlan: () ->

    console.log('Support Plan deactivation')

  renderReact: ->

    <PlanDeactivation.Container
      target="#{@getActivePlan()} SUPPORT PLAN"
      onDeactivation={@bound 'deactivateSupportPlan'} />
