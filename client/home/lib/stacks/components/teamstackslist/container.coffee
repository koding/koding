kd              = require 'kd'
React           = require 'app/react'
EnvironmentFlux = require 'app/flux/environment'
KDReactorMixin  = require 'app/flux/base/reactormixin'
View            = require './view'
SidebarFlux = require 'app/flux/sidebar'


module.exports = class TeamStacksListContainer extends React.Component

  getDataBindings: ->
    return {
      stacks: EnvironmentFlux.getters.teamStacks
      templates: EnvironmentFlux.getters.inUseTeamStackTemplates
      sidebarStacks: SidebarFlux.getters.sidebarStacks
    }


  onAddToSidebar: (stackId) -> SidebarFlux.actions.makeVisible 'stack', stackId


  onRemoveFromSidebar: (stackId) -> SidebarFlux.actions.makeHidden 'stack', stackId


  render: ->
    <View
      stacks={@state.stacks}
      templates={@state.templates}
      sidebarStacks={@state.sidebarStacks}
      onOpenItem={@props.onOpenItem}
      onAddToSidebar={@bound 'onAddToSidebar'}
      onRemoveFromSidebar={@bound 'onRemoveFromSidebar'}
    />

TeamStacksListContainer.include [KDReactorMixin]
