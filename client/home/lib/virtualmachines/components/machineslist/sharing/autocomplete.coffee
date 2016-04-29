kd                  = require 'kd'
React               = require 'kd-react'
Autocomplete        = require 'react-autocomplete'
KDReactorMixin      = require 'app/flux/base/reactormixin'
VirtualMachinesFlux = require 'home/virtualmachines/flux'
Avatar              = require 'app/components/profile/avatar'
ProfileText         = require 'app/components/profile/profiletext'

module.exports = class SharingAutocomplete extends React.Component

  @propTypes    =
    machineId   : React.PropTypes.string.isRequired
    onSelect    : React.PropTypes.func

  @defaultProps =
    onSelect    : kd.noop


  getDataBindings: ->

    return {
      sharingSearchItems: VirtualMachinesFlux.getters.sharingSearchItems @props.machineId
    }


  onSelect: (value, item) ->

    @setState { value : '' }
    VirtualMachinesFlux.actions.resetSearchForSharing @props.machineId
    @props.onSelect value


  onChange: (event, value) ->

    @setState { value }
    VirtualMachinesFlux.actions.searchForSharing value, @props.machineId


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
      value={@state.value}
      items={@state.sharingSearchItems.toJS()}
      getItemValue={@bound 'getItemValue'}
      onSelect={@bound 'onSelect'}
      onChange={@bound 'onChange'}
      renderItem={@bound 'renderItem'}
      renderMenu={@bound 'renderMenu'}
      wrapperStyle={{}}
    />


SharingAutocomplete.include [KDReactorMixin]
