kd              = require 'kd'
React           = require 'app/react'
EnvironmentFlux = require 'app/flux/environment'
KDReactorMixin  = require 'app/flux/base/reactormixin'
View            = require './view'


module.exports = class SharedMachinesListContainer extends React.Component

  getDataBindings: ->
    return {
      machines: EnvironmentFlux.getters.sharedMachines
    }

  render: ->
    <View machines={@state.machines} />

SharedMachinesListContainer.include [KDReactorMixin]
