kd = require 'kd'
React = require 'app/react'
View = require './view'

calculateOwnedResources = require 'app/util/calculateOwnedResources'
canCreateStacks = require 'app/util/canCreateStacks'

module.exports = class DraftsListContainer extends React.Component

  onAddToSidebar: ({ template }) ->

    { sidebar } = kd.singletons

    sidebar.makeVisible 'draft', template.getId()


  onRemoveFromSidebar: ({ template }) ->

    { sidebar } = kd.singletons

    sidebar.makeHidden 'draft', template.getId()


  onCloneFromDashboard: ({ template }) ->

    { router } = kd.singletons

    template.clone (err, template) ->
      if err
        return new kd.NotificationView
          title: "Error occured while cloning template"

      router.handleRoute "/Stack-Editor/#{template.getId()}"


  render: ->
    <View
      resources={@props.resources}
      canCreateStacks={canCreateStacks()}
      onOpenItem={@props.onOpenItem}
      onAddToSidebar={@bound 'onAddToSidebar'}
      onRemoveFromSidebar={@bound 'onRemoveFromSidebar'}
      onCloneFromDashboard={@bound 'onCloneFromDashboard'}
    />
