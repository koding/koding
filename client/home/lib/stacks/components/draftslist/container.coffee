kd              = require 'kd'
React           = require 'kd-react'
EnvironmentFlux = require 'app/flux/environment'
KDReactorMixin  = require 'app/flux/base/reactormixin'
View            = require './view'


module.exports = class DraftsListContainer extends React.Component

  getDataBindings: ->
    return {
      templates: EnvironmentFlux.getters.draftStackTemplates
    }


  onAddToSidebar: (stackTemplateId) -> EnvironmentFlux.actions.generateStack stackTemplateId


  render: ->
    <View templates={@state.templates} onAddToSidebar={@bound 'onAddToSidebar'} />



DraftsListContainer.include [KDReactorMixin]

