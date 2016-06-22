kd              = require 'kd'
React           = require 'kd-react'
View            = require './view'
MiniView        = require './miniview'
HomeFlux        = require 'home/flux'
KDReactorMixin  = require 'app/flux/base/reactormixin'


module.exports = class WelcomeStepsContainer extends React.Component

  getDataBindings: ->
    return {
      steps: HomeFlux.getters.welcomeSteps
    }

  componentWillMount: ->
    HomeFlux.actions.checkMigration()
    HomeFlux.actions.checkFinishedSteps()

  render: ->
    if @props.mini
      <MiniView kdParent={@props.kdParent} steps={@state.steps.toList()}/>
    else
      <View steps={@state.steps.toList()}/>


WelcomeStepsContainer.include [KDReactorMixin]
