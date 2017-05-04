debug = require('debug')('dashboard:draftslist')
kd = require 'kd'
React = require 'app/react'

List = require 'app/components/list'
StackTemplateItem = require '../stacktemplateitem'


module.exports = class DraftsListView extends React.Component

  onCloneHandler: (template) -> @props.onCloneFromDashboard template


  numberOfSections: -> 1


  numberOfRowsInSection: -> @props.resources?.length or 0


  renderSectionHeaderAtIndex: -> null


  renderRowAtIndex: (sectionIndex, rowIndex) ->

    { sidebar } = kd.singletons
    { template, isVisible } = resource = @props.resources[rowIndex]

    <StackTemplateItem
      isVisibleOnSidebar={isVisible}
      template={template}
      canCreateStacks={@props.canCreateStacks}
      onOpen={@props.onOpenItem}
      onAddToSidebar={@props.onAddToSidebar.bind null, resource}
      onRemoveFromSidebar={@props.onRemoveFromSidebar.bind null, resource}
      onCloneFromDashboard={@props.onCloneFromDashboard.bind null, resource}
    />


  renderEmptySectionAtIndex: ->

    children = "You don't have any draft stack templates."

    <div>{children}</div>


  render: ->

    <List
      numberOfSections={@bound 'numberOfSections'}
      numberOfRowsInSection={@bound 'numberOfRowsInSection'}
      renderSectionHeaderAtIndex={@bound 'renderSectionHeaderAtIndex'}
      renderRowAtIndex={@bound 'renderRowAtIndex'}
      renderEmptySectionAtIndex={@bound 'renderEmptySectionAtIndex'}
      sectionClassName='HomeAppViewStackSection'
    />
