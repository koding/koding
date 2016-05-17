kd              = require 'kd'
React           = require 'kd-react'
Member          = require './member'
List            = require 'app/components/list'


module.exports = class HomeTeamTeamMatesView extends React.Component

  numberOfSections: -> 1


  numberOfRowsInSection: ->

    @props.members?.size or 0


  renderSectionHeaderAtIndex: -> null


  renderRowAtIndex: (sectionIndex, rowIndex) ->

    member = @props.members.toList().get(rowIndex)
    key = member?.get '_id'
    <Member
      key={key}
      member={member}
      handleInvitation={@props.handleInvitation}
      handleDisabledUser={@props.handleDisabledUser}
      handleRoleChange={@props.handleRoleChange} />  if member


  renderEmptySectionAtIndex: -> <div> No data found</div>


  render: ->

    # commented out until we have a functioning design - SY

    # <SearchBox
    #   onChange={@props.onSearchInputChange}
    #   value={@props.searchInputValue} />

    <div>
      <List
        numberOfSections={@bound 'numberOfSections'}
        numberOfRowsInSection={@bound 'numberOfRowsInSection'}
        renderSectionHeaderAtIndex={@bound 'renderSectionHeaderAtIndex'}
        renderRowAtIndex={@bound 'renderRowAtIndex'}
        renderEmptySectionAtIndex={@bound 'renderEmptySectionAtIndex'}
        rowClassName='HomeApp-Teammate--ListItem'
        sectionClassName='HomeApp-TeammatesSection'
      />
    </div>


SearchBox = ({ onChange, value }) ->

  <div className='search'>
    <span className='label'>Filter</span>
    <input
      type='text'
      className='kdinput text hitenterview'
      onChange={onChange}
      placeholder='Find by name/username'
      value={value} />
  </div>
