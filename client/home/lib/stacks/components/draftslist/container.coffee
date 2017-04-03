kd = require 'kd'
React = require 'app/react'
EnvironmentFlux = require 'app/flux/environment'
KDReactorMixin = require 'app/flux/base/reactormixin'
remote = require 'app/remote'
View = require './view'
SidebarFlux = require 'app/flux/sidebar'

calculateOwnedResources = require 'app/util/calculateOwnedResources'

module.exports = class DraftsListContainer extends React.Component

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


  onAddToSidebar: (resource) ->

    { sidebar } = kd.singletons

    sidebar.makeVisible 'draft', resource.template.getId()


  onRemoveFromSidebar: ({ template }) ->

    { sidebar } = kd.singletons

    sidebar.makeHidden 'draft', template.getId()


  onCloneFromDashboard: ({ template }) ->

    { router } = kd.singletons

    console.trace()

    template.clone (err, template) =>
      if err
        return new kd.NotificationView
          title: "Error occured while cloning template"

      router.handleRoute "/Stack-Editor/#{template.getId()}"


  render: ->
    <View
      resources={@state.resources}
      sidebarDrafts={@state.sidebarDrafts}
      onOpenItem={@props.onOpenItem}
      onAddToSidebar={@bound 'onAddToSidebar'}
      onRemoveFromSidebar={@bound 'onRemoveFromSidebar'}
      onCloneFromDashboard={@bound 'onCloneFromDashboard'}
    />
