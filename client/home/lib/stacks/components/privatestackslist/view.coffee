kd = require 'kd'
React = require 'app/react'

List = require 'app/components/list'
StackTemplateItem = require '../stacktemplateitem'


module.exports = class PrivateStacksListView extends React.Component

  onAddToSidebar: (stack) -> @props.onAddToSidebar stack.get '_id'


  onRemoveFromSidebar: (stack) -> @props.onRemoveFromSidebar stack.get '_id'


  numberOfSections: -> 1


  numberOfRowsInSection: -> @props.stacks?.size or 0


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
      onOpen={@props.onOpenItem}
      onAddToSidebar={onAddToSidebar}
      onRemoveFromSidebar={onRemoveFromSidebar}
      stack={stack}
    />


  renderEmptySectionAtIndex: -> <div>You don't have any private stacks ready.</div>


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
