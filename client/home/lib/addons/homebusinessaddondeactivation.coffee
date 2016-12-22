React = require 'app/react'
ReactView = require 'app/react/reactview'
PlanDeactivation = require './components/plandeactivation'

module.exports = class HomeBusinessAddOnDeactivation extends ReactView

  constructor: (options = {}, data) ->

    super options, data

  deactivateBusinessAddOn: () ->

    console.log('Business Add-On deactivation')

  renderReact: ->
    
    <PlanDeactivation.Container
      target='BUSINESS ADD-ON'
      onDeactivation={@bound 'deactivateBusinessAddOn'} />
