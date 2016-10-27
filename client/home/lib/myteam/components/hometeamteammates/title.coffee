kd    = require 'kd'
React = require 'app/react'
TeamFlux       = require 'app/flux/teams'
ButtonWithMenu = require 'app/components/buttonwithmenu'
capitalizeFirstLetter = require 'app/util/capitalizefirstletter'

module.exports = class HomeTeamTeamMatesTitle extends React.Component

  constructor: (props) ->

    super props

    @state = 
      isMenuOpen: no
      filterValue: 'See All'


  onClickFilter: (event) ->

    kd.utils.stopDOMEvent event
    @setState { isMenuOpen: yes }
    
      
  onClickTitle: (event) ->
    if hash = event.target?.hash
      window.location.replace hash
  
    
  handleFilterChange: (key, value) ->
    @setState { isMenuOpen: no }
    @setState { filterValue: value }
    TeamFlux.actions.setRoleFilterKey key
    
    
  getMenuItems: ->
    return [
      { title: 'See All', key: 'all', onClick: @handleFilterChange.bind(this, 'all', 'See All') }
      { title: 'Only Admins', key: 'admin', onClick: @handleFilterChange.bind(this, 'admin', 'Only Admins') }
      { title: 'Only Members', key: 'member', onClick: @handleFilterChange.bind(this, 'member', 'Only Members') }
      { title: 'Only Invited', key: 'invite', onClick: @handleFilterChange.bind(this, 'invited', 'Only Invited') }
      { title: 'Only Disabled Users', key: 'disable', onClick: @handleFilterChange.bind(this, 'disabled', 'Only Disabled Users') }
    ]


  render: ->

    <div className="sectionHeader">
      <TeammateTitle onClick={@bound 'onClickTitle'} />
      <FilterWithDropDownMenu
        items={@getMenuItems()}
        onClick={@bound 'onClickFilter'}
        isMenuOpen={@state.isMenuOpen}
        filterValue={@state.filterValue} />
      <div className="clearfix"></div>
    </div>

TeammateTitle = ({ onClick }) ->
  <div className="HomeTeamTeammatesTitle" onClick={onClick}>
    <a href="#teammates">
      <svg className="anchor" aria-hidden="true" height="16" version="1.1" viewBox="0 0 16 16" width="16">
        <path fill="#9f9f9f" d="M12 4h-2.156c0.75 0.5 1.453 1.391 1.672 2h0.469c1.016 0 2 1 2 2s-1.016 2-2 2h-3c-0.984 0-2-1-2-2 0-0.359 0.109-0.703 0.281-1h-2.141c-0.078 0.328-0.125 0.656-0.125 1 0 2 1.984 4 3.984 4s1.016 0 3.016 0 4-2 4-4-2-4-4-4zM4.484 10h-0.469c-1.016 0-2-1-2-2s1.016-2 2-2h3c0.984 0 2 1 2 2 0 0.359-0.109 0.703-0.281 1h2.141c0.078-0.328 0.125-0.656 0.125-1 0-2-1.984-4-3.984-4s-1.016 0-3.016 0-4 2-4 4 2 4 4 4h2.156c-0.75-0.5-1.453-1.391-1.672-2z" />
      </svg>
      Teammates
    </a>
  </div>

FilterWithDropDownMenu = ({ onClick, items, isMenuOpen, filterValue }) ->
  
  <div className='HomeTeamTeammatesDropdown' onClick={onClick}>
    <FilterValue filterValue={filterValue} />
    <ButtonWithMenu menuClassName='menu-class' items={items} isMenuOpen={isMenuOpen} />
  </div>


FilterValue = ({ filterValue }) ->

  className = 'role'

  <div className={className}>{filterValue}</div>
