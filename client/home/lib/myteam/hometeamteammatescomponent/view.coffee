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
      member={member} />  if member


  renderEmptySectionAtIndex: -> <div> No data found</div>


  renderSearchBox: ->
    <div className='search'>
      <span className='label'>Filter</span>
      <input
        type='text'
        className='kdinput text hitenterview'
        onChange={@props.onSearchInputChange}
        placeholder='Find by name/username'
        value={@props.searchInputValue} />
    </div>


  render: ->
    <div>
      {@renderSearchBox()}
      <div className='kdview kdlistview kdlistview-default'>
        <List
          numberOfSections={@bound 'numberOfSections'}
          numberOfRowsInSection={@bound 'numberOfRowsInSection'}
          renderSectionHeaderAtIndex={@bound 'renderSectionHeaderAtIndex'}
          renderRowAtIndex={@bound 'renderRowAtIndex'}
          renderEmptySectionAtIndex={@bound 'renderEmptySectionAtIndex'}
        />
      </div>
    </div>