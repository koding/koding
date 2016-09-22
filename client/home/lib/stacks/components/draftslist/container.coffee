kd              = require 'kd'
React           = require 'app/react'
EnvironmentFlux = require 'app/flux/environment'
KDReactorMixin  = require 'app/flux/base/reactormixin'
View            = require './view'
SidebarFlux = require 'app/flux/sidebar'


module.exports = class DraftsListContainer extends React.Component

  getDataBindings: ->
    return {
      templates: EnvironmentFlux.getters.draftStackTemplates
      sidebarDrafts: SidebarFlux.getters.sidebarDrafts
    }


  onAddToSidebar: (stackTemplateId) ->

    SidebarFlux.actions.makeVisible 'draft', stackTemplateId


  onRemoveFromSidebar: (stackTemplateId) ->

    SidebarFlux.actions.makeHidden 'draft', stackTemplateId


  render: ->
    <View
      templates={@state.templates}
      sidebarDrafts={@state.sidebarDrafts}
      onOpenItem={@props.onOpenItem}
      onAddToSidebar={@bound 'onAddToSidebar'}
      onRemoveFromSidebar={@bound 'onRemoveFromSidebar'}
    />


DraftsListContainer.include [KDReactorMixin]

