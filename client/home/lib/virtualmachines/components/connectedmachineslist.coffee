kd              = require 'kd'
React           = require 'kd-react'
EnvironmentFlux = require 'app/flux/environment'
KDReactorMixin  = require 'app/flux/base/reactormixin'
List            = require './machineslist/list'


module.exports = class ConnectedMachinesListContainer extends React.Component

  getDataBindings: ->
    return {
      stacks: EnvironmentFlux.getters.stacks
    }


  render: ->

    stacks = @state.stacks.toList()
      .filter (stack) -> stack.get('title').toLowerCase() is 'managed vms'

    <List
      stacks={stacks}
      shouldRenderDetails={no} />


ConnectedMachinesListContainer.include [KDReactorMixin]


