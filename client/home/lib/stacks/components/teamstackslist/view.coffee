debug = require('debug')('dashboard:teamstacks')
kd = require 'kd'
React = require 'app/react'

List = require 'app/components/list'
StackTemplateItem = require '../stacktemplateitem'

module.exports = class TeamStacksListView extends React.Component

  getResources: ->

    resources = (@props.resources or []).filter (resource) ->
      resource.stack and resource.template?.accessLevel isnt 'private'

    debug 'resources requested', resources

    return resources


  numberOfSections: -> 1


  numberOfRowsInSection: -> @getResources().length


  renderSectionHeaderAtIndex: -> null


  renderRowAtIndex: (sectionIndex, rowIndex) ->

    { sidebar } = kd.singletons

    resource = @getResources()[rowIndex]

    { stack, template } = resource

    isVisible = if stack
    then sidebar.isVisible 'stack', stack.getId()
    else sidebar.isVisible 'draft', template.getId()

    <StackTemplateItem
      isVisibleOnSidebar={isVisible}
      stack={stack}
      template={template}
      onOpen={@props.onOpenItem}
      onAddToSidebar={@props.onAddToSidebar.bind null, resource}
      onRemoveFromSidebar={@props.onRemoveFromSidebar.bind null, resource}
    />


  renderEmptySectionAtIndex: ->
    <div>Your team does not have any stacks ready.</div>


  render: ->

    <List
      numberOfSections={@bound 'numberOfSections'}
      numberOfRowsInSection={@bound 'numberOfRowsInSection'}
      renderSectionHeaderAtIndex={@bound 'renderSectionHeaderAtIndex'}
      renderRowAtIndex={@bound 'renderRowAtIndex'}
      renderEmptySectionAtIndex={@bound 'renderEmptySectionAtIndex'}
      sectionClassName='HomeAppViewStackSection'
      rowClassName='stack-type'
    />
