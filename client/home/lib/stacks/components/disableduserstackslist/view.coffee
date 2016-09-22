kd = require 'kd'
React = require 'app/react'

List = require 'app/components/list'
StackTemplateItem = require '../stacktemplateitem'

module.exports = class DisabledUsersStacksListView extends React.Component

  onAddToSidebar: (template) -> @props.onAddToSidebar template.get '_id'


  onRemoveFromSidebar: (template) -> @props.onRemoveFromSidebar template.get '_id'


  numberOfSections: -> 1


  numberOfRowsInSection: -> @props.templates?.size or 0


  renderSectionHeaderAtIndex: -> null


  renderRowAtIndex: (sectionIndex, rowIndex) ->

    stack = @props.stacks.toList().get(rowIndex)
    template = @props.templates.get stack.get 'baseStackId'

    onAddToSidebar = @lazyBound 'onAddToSidebar', stack
    onRemoveFromSidebar = @lazyBound 'onRemoveFromSidebar', stack

    isVisible = !!@props.sidebarStacks.get(stack.get '_id')

    <StackTemplateItem
      isVisibleOnSidebar={isVisible}
      template={template}
      stack={stack}
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


