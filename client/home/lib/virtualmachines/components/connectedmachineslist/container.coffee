kd              = require 'kd'
React           = require 'kd-react'
EnvironmentFlux = require 'app/flux/environment'
KDReactorMixin  = require 'app/flux/base/reactormixin'
View            = require './view'

module.exports = class ConnectedMachinesListContainer extends React.Component

  getDataBindings: ->
    return {
      stacks: EnvironmentFlux.getters.stacks
    }

  render: ->
    <View stacks={@state.stacks} />

ConnectedMachinesListContainer.include [KDReactorMixin]
