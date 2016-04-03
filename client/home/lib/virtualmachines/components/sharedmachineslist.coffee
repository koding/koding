kd              = require 'kd'
React           = require 'kd-react'
EnvironmentFlux = require 'app/flux/environment'
KDReactorMixin  = require 'app/flux/base/reactormixin'
immutable       = require 'immutable'
List            = require './machineslist/list'


module.exports = class SharedMachinesListContainer extends React.Component

  getDataBindings: ->
    return {
      machines: EnvironmentFlux.getters.sharedMachines
    }


  render: ->

    stacks = immutable.List [
      immutable.Map {
        title: 'Shared Machine'
        machines: @state.machines or immutable.Map({})
      }
    ]

    <List
      stacks={stacks}
      shouldRenderDetails={no} />


SharedMachinesListContainer.include [KDReactorMixin]


