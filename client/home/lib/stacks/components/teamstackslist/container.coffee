kd              = require 'kd'
React           = require 'app/react'
EnvironmentFlux = require 'app/flux/environment'
View            = require './view'

calculateOwnedResources = require 'app/util/calculateOwnedResources'

module.exports = class TeamStacksListContainer extends React.Component

  constructor: (props) ->
    super props

    @state =
      resources: calculateOwnedResources @props
      loading: yes


  componentDidMount: ->

    { computeController, mainController } = kd.singletons

    mainController.ready =>
      computeController.fetchStackTemplates =>
        @setState {
          resources: calculateOwnedResources @props, @state
        }, => @setState { loading: no }


  componentWillReceiveProps: (nextProps, nextState) ->

    @setState
      resources: calculateOwnedResources nextProps, nextState


  onAddToSidebar: ({ template, stack }) ->

    { sidebar } = kd.singletons

    if stack
    then sidebar.setVisible 'stack', stack.getId()
    else sidebar.setVisible 'draft', template.getId()


  onRemoveFromSidebar: ({ template, stack }) ->

    { sidebar } = kd.singletons

    if stack
    then sidebar.setHidden 'stack', stack.getId()
    else sidebar.setHidden 'draft', template.getId()


  render: ->

    <View
      resources={@state.resources}
      onOpenItem={@props.onOpenItem}
      onAddToSidebar={@bound 'onAddToSidebar'}
      onRemoveFromSidebar={@bound 'onRemoveFromSidebar'}
    />
