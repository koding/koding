kd              = require 'kd'
React           = require 'kd-react'
View            = require './view'
HomeFlux        = require 'home/flux'
KDReactorMixin  = require 'app/flux/base/reactormixin'


module.exports = class WelcomeStepsContainer extends React.Component

  getDataBindings: ->
    return {
      steps: HomeFlux.getters.welcomeSteps
    }


  render: ->
    <View steps={@state.steps.toList()}/>


WelcomeStepsContainer.include [KDReactorMixin]
