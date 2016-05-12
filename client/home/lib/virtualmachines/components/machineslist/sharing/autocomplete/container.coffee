kd                  = require 'kd'
React               = require 'kd-react'
KDReactorMixin      = require 'app/flux/base/reactormixin'
VirtualMachinesFlux = require 'home/virtualmachines/flux'
View                = require './view'

module.exports = class SharingAutocompleteContainer extends React.Component

  @propTypes    =
    machineId   : React.PropTypes.string.isRequired
    onSelect    : React.PropTypes.func

  @defaultProps =
    onSelect    : kd.noop


  getDataBindings: ->

    return {
      searchItems: VirtualMachinesFlux.getters.sharingSearchItems @props.machineId
    }


  onSelect: (value, item) ->

    @setState { value : '' }
    VirtualMachinesFlux.actions.resetSearchForSharing @props.machineId
    @props.onSelect value


  onChange: (event, value) ->

    @setState { value }
    VirtualMachinesFlux.actions.searchForSharing value, @props.machineId


  render: ->

    <View
      value={@state.value}
      searchItems={@state.searchItems}
      onSelect={@bound 'onSelect'}
      onChange={@bound 'onChange'}
    />


SharingAutocompleteContainer.include [KDReactorMixin]
