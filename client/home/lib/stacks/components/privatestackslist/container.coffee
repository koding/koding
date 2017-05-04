kd              = require 'kd'
React           = require 'app/react'
EnvironmentFlux = require 'app/flux/environment'
View            = require './view'

module.exports = class PrivateStacksListContainer extends React.Component

  onAddToSidebar: ({ stack, template }) ->

    { sidebar } = kd.singletons

    if stack
    then sidebar.makeVisible 'stack', stack.getId()
    else sidebar.makeVisible 'draft', template.getId()


  onRemoveFromSidebar: ({ stack, template }) ->

    { sidebar } = kd.singletons

    if stack
    then sidebar.makeHidden 'stack', stack.getId()
    else sidebar.makeHidden 'draft', template.getId()


  render: ->
    <View
      resources={@props.resources}
      onOpenItem={@props.onOpenItem}
      onAddToSidebar={@bound 'onAddToSidebar'}
      onRemoveFromSidebar={@bound 'onRemoveFromSidebar'}
    />
