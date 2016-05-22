kd              = require 'kd'
React           = require 'kd-react'
EnvironmentFlux = require 'app/flux/environment'
KDReactorMixin  = require 'app/flux/base/reactormixin'
View            = require './view'
SidebarFlux = require 'app/flux/sidebar'


module.exports = class DisabledMembersStacksListContainer extends React.Component

  getDataBindings: ->
    return {
      templates: EnvironmentFlux.getters.disabledMembersStackTemplates
      sidebarStacks: SidebarFlux.getters.sidebarStacks
    }


  onAddToSidebar: (stackTemplateId) ->

    SidebarFlux.actions.makeVisible 'stack', stackTemplateId


  onRemoveFromSidebar: (stackTemplateId) ->

    SidebarFlux.actions.makeHidden 'stack', stackTemplateId


  render: ->

    <View
      templates={@state.templates}
      sidebarStacks={@state.sidebarStacks}
      onOpenItem={@props.onOpenItem}
      onAddToSidebar={@bound 'onAddToSidebar'}
      onRemoveFromSidebar={@bound 'onRemoveFromSidebar'}
    />


DisabledMembersStacksListContainer.include [KDReactorMixin]
