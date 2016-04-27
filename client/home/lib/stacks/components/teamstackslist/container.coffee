kd              = require 'kd'
React           = require 'kd-react'
EnvironmentFlux = require 'app/flux/environment'
KDReactorMixin  = require 'app/flux/base/reactormixin'
View            = require './view'


module.exports = class TeamStacksListContainer extends React.Component

  getDataBindings: ->
    return {
      templates: EnvironmentFlux.getters.inUseTeamStackTemplates
    }


  onAddToSidebar: (stackTemplateId) -> EnvironmentFlux.actions.generateStack stackTemplateId


  render: ->
    <View templates={@state.templates} onAddToSidebar={@bound 'onAddToSidebar'} />

TeamStacksListContainer.include [KDReactorMixin]

