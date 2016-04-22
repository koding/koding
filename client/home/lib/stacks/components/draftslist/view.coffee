kd = require 'kd'
React = require 'kd-react'

List = require 'app/components/list'
StackTemplateItem = require '../stacktemplateitem'


module.exports = class DraftsListView extends React.Component

  numberOfSections: -> 1


  numberOfRowsInSection: -> @props.templates?.size or 0


  renderSectionHeaderAtIndex: -> null


  renderRowAtIndex: (sectionIndex, rowIndex) ->

    template = @props.templates.toList().get(rowIndex)

    <StackTemplateItem template={template} />


  renderEmptySectionAtIndex: -> <div>No team stacks</div>


  render: ->

    <List
      numberOfSections={@bound 'numberOfSections'}
      numberOfRowsInSection={@bound 'numberOfRowsInSection'}
      renderSectionHeaderAtIndex={@bound 'renderSectionHeaderAtIndex'}
      renderRowAtIndex={@bound 'renderRowAtIndex'}
      renderEmptySectionAtIndex={@bound 'renderEmptySectionAtIndex'}
    />

