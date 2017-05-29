React = require 'app/react'

List = require 'app/components/list'

OwnedResourcesList = require './ownedresourceslist'
SharedResourcesList = require './sharedresourceslist'
SidebarGroupDisabled = require './sidebargroupdisabled'
sections = ['owned', 'shared']

module.exports = class SidebarResources extends React.Component

  @propTypes =
    owned: React.PropTypes.array
    shared: React.PropTypes.shape
      permanent: React.PropTypes.array
      collaboration: React.PropTypes.array
    disabled: React.PropTypes.bool


  getSectionCount: ->

    # owned resources is always rendered, even with no items (with empty
    # message), but shared resources will be shown only if there is at least 1
    # shared resource.
    { shared: { permanent, collaboration } } = @props

    return if permanent.length or collaboration.length then 2 else 1


  getRowCount: (sectionIndex) -> 1


  renderRowAtIndex: (sectionIndex) ->

    { owned, shared } = @props

    switch sections[sectionIndex]
      when 'owned'
        <OwnedResourcesList
          resources={owned}
          hasTemplate={@props.hasTemplate}
        />
      when 'shared'
        <SharedResourcesList resources={shared} />


  render: ->

    <div className='SidebarResources'>

      {@props.disabled and
        <SidebarGroupDisabled />}

      {not @props.loading and not @props.disabled and
        <List
          numberOfSections={@bound 'getSectionCount'}
          numberOfRowsInSection={@bound 'getRowCount'}
          renderRowAtIndex={@bound 'renderRowAtIndex'} />}

    </div>
