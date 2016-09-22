kd                  = require 'kd'
immutable           = require 'immutable'
React               = require 'app/react'
Autocomplete        = require 'react-autocomplete'
Avatar              = require 'app/components/profile/avatar'
ProfileText         = require 'app/components/profile/profiletext'

module.exports = class SharingAutocompleteView extends React.Component

  @propTypes    =
    value       : React.PropTypes.string
    searchItems : React.PropTypes.instanceOf immutable.List
    onSelect    : React.PropTypes.func
    onChange    : React.PropTypes.func

  @defaultProps =
    value       : ''
    searchItems : immutable.List()
    onSelect    : kd.noop
    onChange    : kd.noop


  getItemValue: (item) -> item.profile.nickname


  renderMenu: (items, value, style) ->

    className  = 'AutocompleteList'
    className += ' hidden'  unless items.length

    <div style={style} className={className}>
      {items}
    </div>


  renderItem: (item, isHighlighted) ->

    className  = 'AutocompleteListItem'
    className += ' active'  if isHighlighted

    <div key={item._id} className={className}>
      <Avatar width=25 height=25 account={item} />
      <ProfileText account={item} />
    </div>


  render: ->

    <Autocomplete
      inputProps={ {placeholder: 'Type a username', className: 'kdinput text'} }
      ref='autocomplete'
      value={@props.value}
      items={@props.searchItems.toJS()}
      getItemValue={@bound 'getItemValue'}
      onSelect={@props.onSelect}
      onChange={@props.onChange}
      renderItem={@bound 'renderItem'}
      renderMenu={@bound 'renderMenu'}
      wrapperStyle={{}}
    />
