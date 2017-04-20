kd = require 'kd'
React = require 'app/react'

List = require 'app/components/list'
StackTemplateItem = require '../stacktemplateitem'

module.exports = class DisabledUsersStacksListView extends React.Component

  numberOfSections: -> 1


  numberOfRowsInSection: -> @props.resources?.length or 0


  renderSectionHeaderAtIndex: -> null


  renderRowAtIndex: (sectionIndex, rowIndex) ->

    resource = @props.resources[rowIndex]

    { stack, template, isVisible } = resource

    <StackTemplateItem
      isVisibleOnSidebar={isVisible}
      stack={stack}
      template={template}
      onOpen={@props.onOpenItem}
      onAddToSidebar={@props.onAddToSidebar.bind null, resource}
      onRemoveFromSidebar={@props.onRemoveFromSidebar.bind null, resource}
    />


  renderEmptySectionAtIndex: ->
    <div>There is no disabled user stacks.</div>


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
