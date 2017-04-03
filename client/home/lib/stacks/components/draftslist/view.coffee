debug = require('debug')('dashboard:draftslist')
kd = require 'kd'
React = require 'app/react'

List = require 'app/components/list'
StackTemplateItem = require '../stacktemplateitem'


module.exports = class DraftsListView extends React.Component

  getResources: ->

    resources = (@props.resources or []).filter (resource) -> not resource.stack

    debug 'resources requested', resources

    return resources


  onAddToSidebar: (template) -> @props.onAddToSidebar template.get '_id'


  onRemoveFromSidebar: (template) -> @props.onRemoveFromSidebar template.get '_id'


  onCloneHandler: (template) -> @props.onCloneFromDashboard template


  numberOfSections: -> 1


  numberOfRowsInSection: -> @getResources().length


  renderSectionHeaderAtIndex: -> null


  renderRowAtIndex: (sectionIndex, rowIndex) ->

    { sidebar } = kd.singletons
    { template } = resource = @getResources()[rowIndex]

    <StackTemplateItem
      isVisibleOnSidebar={sidebar.isVisible 'draft', template.getId()}
      template={template}
      onOpen={@props.onOpenItem}
      onAddToSidebar={=> @props.onAddToSidebar resource}
      onRemoveFromSidebar={=> @props.onRemoveFromSidebar resource}
      onCloneFromDashboard={=> @props.onCloneFromDashboard resource}
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
