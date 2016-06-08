kd = require 'kd'
React = require 'kd-react'

List = require 'app/components/list'
StackTemplateItem = require '../stacktemplateitem'

module.exports = class DisabledUsersStacksListView extends React.Component

  onAddToSidebar: (template) -> @props.onAddToSidebar template.get '_id'


  onRemoveFromSidebar: (template) -> @props.onRemoveFromSidebar template.get '_id'


  numberOfSections: -> 1


  numberOfRowsInSection: -> @props.templates?.size or 0


  renderSectionHeaderAtIndex: -> null


  renderRowAtIndex: (sectionIndex, rowIndex) ->

    template = @props.templates.toList().get(rowIndex)
    onAddToSidebar = @lazyBound 'onAddToSidebar', template
    onRemoveFromSidebar = @lazyBound 'onRemoveFromSidebar', template

    stacks = @props.sidebarStacks.toList().filter (s) ->
      s.hasIn(['config', 'oldOwner']) and s.get('baseStackId') is template.get('_id')

    isVisible = stacks.size > 0

    <StackTemplateItem
      isVisibleOnSidebar={isVisible}
      template={template}
      stack={stacks.get(0)}
      onOpen={@props.onOpenItem}
      onAddToSidebar={onAddToSidebar}
      onRemoveFromSidebar={onRemoveFromSidebar}
    />


  renderEmptySectionAtIndex: -> <div>Your team doesn't have any stacks ready.</div>


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


