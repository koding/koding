kd                  = require 'kd'
React               = require 'app/react'
KDReactorMixin      = require 'app/flux/base/reactormixin'
VirtualMachinesSearchFlux = require 'home/virtualmachines/flux/search'
View                = require './view'

module.exports = class SharingAutocompleteContainer extends React.Component

  @propTypes    =
    machineId   : React.PropTypes.string.isRequired
    onSelect    : React.PropTypes.func

  @defaultProps =
    onSelect    : kd.noop


  getDataBindings: ->

    return {
      searchItems: VirtualMachinesSearchFlux.getters.sharingSearchItems @props.machineId
    }


  onSelect: (value, item) ->

    @setState { value : '' }
    VirtualMachinesSearchFlux.actions.resetSearchForSharing @props.machineId
    @props.onSelect value


  onChange: (event, value) ->

    @setState { value }
    VirtualMachinesSearchFlux.actions.searchForSharing value, @props.machineId


  render: ->

    <View
      value={@state.value}
      searchItems={@state.searchItems}
      onSelect={@bound 'onSelect'}
      onChange={@bound 'onChange'}
    />


SharingAutocompleteContainer.include [KDReactorMixin]
