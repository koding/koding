kd = require 'kd'
React = require 'app/react'
View = require './view'


module.exports = class DisabledUserStacksListContainer extends React.Component

  onAddToSidebar: ({ template, stack }) ->

    { sidebar } = kd.singletons

    if stack
    then sidebar.makeVisible 'stack', stack.getId()
    else sidebar.makeVisible 'draft', template.getId()


  onRemoveFromSidebar: ({ template, stack }) ->

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
