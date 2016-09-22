kd              = require 'kd'
React           = require 'app/react'
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

    # this is required because we are only checking the state when we are
    # mounting the component. These checks need to be done when the backend is
    # ready, because mini view will be rendered on the page load. ~Umut
    kd.singletons.mainController.ready =>
      HomeFlux.actions.checkFinishedSteps()


  render: ->
    if @props.mini
      <MiniView kdParent={@props.kdParent} steps={@state.steps.toList()} onSkipClick={kd.noop}/>
    else
      <View steps={@state.steps} onSkipClick={@bound 'onSkipClick'}/>


  onSkipClick: (key) -> HomeFlux.actions.markAsDone key


WelcomeStepsContainer.include [KDReactorMixin]
