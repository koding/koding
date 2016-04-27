kd = require 'kd'
React = require 'kd-react'

List = require 'app/components/list'
StackTemplateItem = require '../stacktemplateitem'

module.exports = class TeamStacksListView extends React.Component

  onAddToSidebar: (template) -> @props.onAddToSidebar template.get '_id'


  numberOfSections: -> 1


  numberOfRowsInSection: -> @props.templates?.size or 0


  renderSectionHeaderAtIndex: -> null


  renderRowAtIndex: (sectionIndex, rowIndex) ->

    template = @props.templates.toList().get(rowIndex)
    onAddToSidebar = @lazyBound 'onAddToSidebar', template

    <StackTemplateItem template={template} onAddToSidebar={onAddToSidebar} />


  renderEmptySectionAtIndex: -> <div>No team stacks</div>


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
