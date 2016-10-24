kd    = require 'kd'
React = require 'app/react'
TeamFlux       = require 'app/flux/teams'
ButtonWithMenu = require 'app/components/buttonwithmenu'
capitalizeFirstLetter = require 'app/util/capitalizefirstletter'

module.exports = class HomeTeamTeamMatesTitle extends React.Component

  constructor: (props) ->

    super props

    @state = {
      isMenuOpen: no
      filterKey: 'all'
    }

    @filterValue = 'See All'


  onClickFilter: (event) ->

    kd.utils.stopDOMEvent event
    @setState { isMenuOpen: yes }
    
      
  onClickTitle: (event) ->
    if hash = event.target?.hash
      window.location.replace hash
  
    
  handleFilterChange: (key, value) ->
    @props.filterValue = value
    @setState { isMenuOpen: no }
    @filterValue = value
    TeamFlux.actions.setRoleFilterKey key


  getFilterValue: ->
    return @filterValue
    
    
  getMenuItems: ->

    items = []
    items.push { title: 'See All', key: 'all', onClick: @handleFilterChange.bind(this, 'all', 'See All') }
    items.push { title: 'Only Admins', key: 'admin', onClick: @handleFilterChange.bind(this, 'admin', 'Only Admins') }
    items.push { title: 'Only Members', key: 'member', onClick: @handleFilterChange.bind(this, 'member', 'Only Members') }
    items.push { title: 'Only Invited', key: 'invite', onClick: @handleFilterChange.bind(this, 'invited', 'Only Invited') }
    items.push { title: 'Only Disabled Users', key: 'disable', onClick: @handleFilterChange.bind(this, 'disabled', 'Only Disabled Users') }

    return items


  render: ->

    <div className="teammate-header">
      <TeammateTitle onClick={@onClickTitle.bind(this)} />
      <FilterWithDropDownMenu
        items={@getMenuItems()}
        onClick={@onClickFilter.bind(this)}
        isMenuOpen={@state.isMenuOpen}
        filterValue={@getFilterValue()} />
      <div className="clearfix"></div>
    </div>

TeammateTitle = ({ onClick }) ->
  domId  = kd.utils.slugify "Teammates"
  <div className="title" onClick={onClick}>
    <a href="##{domId}">
      <svg className="anchor" aria-hidden="true" height="16" version="1.1" viewBox="0 0 16 16" width="16">
        <path fill="#9f9f9f" d="M12 4h-2.156c0.75 0.5 1.453 1.391 1.672 2h0.469c1.016 0 2 1 2 2s-1.016 2-2 2h-3c-0.984 0-2-1-2-2 0-0.359 0.109-0.703 0.281-1h-2.141c-0.078 0.328-0.125 0.656-0.125 1 0 2 1.984 4 3.984 4s1.016 0 3.016 0 4-2 4-4-2-4-4-4zM4.484 10h-0.469c-1.016 0-2-1-2-2s1.016-2 2-2h3c0.984 0 2 1 2 2 0 0.359-0.109 0.703-0.281 1h2.141c0.078-0.328 0.125-0.656 0.125-1 0-2-1.984-4-3.984-4s-1.016 0-3.016 0-4 2-4 4 2 4 4 4h2.156c-0.75-0.5-1.453-1.391-1.672-2z" />
      </svg>
      Teammates
    </a>
  </div>

FilterWithDropDownMenu = ({ onClick, items, isMenuOpen, filterValue }) ->
  
  <div className='dropdown' onClick={onClick}>
    <FilterValue showPointer={yes} filterValue={filterValue}/>
    <ButtonWithMenu menuClassName='menu-class' items={items} isMenuOpen={isMenuOpen} />
  </div>


FilterValue = ({ showPointer, filterValue }) ->

  className = 'role'
  className = 'role showPointer'  if showPointer

  <div className={className}>{filterValue}</div>
