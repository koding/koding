kd              = require 'kd'
React           = require 'kd-react'
EnvironmentFlux = require 'app/flux/environment'
KDReactorMixin  = require 'app/flux/base/reactormixin'
View            = require './view'


module.exports = class PrivateStacksListContainer extends React.Component

  getDataBindings: ->
    return {
      templates: EnvironmentFlux.getters.inUsePrivateStackTemplates
    }

  render: ->
    <View templates={@state.templates}/>


PrivateStacksListContainer.include [KDReactorMixin]

