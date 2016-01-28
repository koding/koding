kd                  = require 'kd'
React               = require 'kd-react'
Popover             = require 'app/components/common/popover'
SidebarWidget       = require './sidebarwidget'
EnvironmentFlux     = require 'app/flux/environment'
KDReactorMixin      = require 'app/flux/base/reactormixin'
actions             = require 'app/flux/environment/actions'


PROVIDERS         =
  AWS             : 'Amazon'
  Azure           : 'Azure'
  HPCloud         : 'HP Cloud'
  Joyent          : 'Joyent'
  SoftLayer       : 'SoftLayer'
  Rackspace       : 'Rackspace'
  GoogleCloud     : 'Google Cloud'
  DigitalOcean    : 'DigitalOcean'
  UnknownProvider : '' # no custom name for unknown providers


module.exports = class ConnectedManagedMachineWidget extends React.Component

  @defaultProps =
    className : 'ConnectedManagedVm sidebar-info-modal'

  getDataBindings: ->
    connectedManagedMachine: EnvironmentFlux.getters.connectedManagedMachine


  removeFromStore: ->

    kd.utils.defer =>
      actions.hideManagedMachineAddedModal @props.machine.get '_id'


  handleButtonClick: ->

    @removeFromStore()
    kd.singletons.router.handleRoute "/IDE/#{@props.machine.get('slug')}"


  render: ->

    connectedMachine = @state.connectedManagedMachine.get @props.machine.get('_id')

    return null  unless connectedMachine

    provider = if PROVIDERS[connectedMachine.providerName] then connectedMachine.providerName else 'UnknownProvider'

    <SidebarWidget {...@props} onClose={@bound 'removeFromStore'}>
      <div className='artboard'>
        <img
          className="#{PROVIDERS[provider]}"
          src="/a/images/providers/#{provider.toLowerCase()}.png"
          />
      </div>
      <h2>Your {PROVIDERS[provider] or ''} machine is now connected!</h2>
      <p>
        You may now use this machine just like you use your Koding VM.
        You can open files, terminals and even initiate collaboration session.
      </p>
      <button className='kdbutton solid green medium close' onClick={@bound 'handleButtonClick'}>
        <span className='icon check'></span>
        <span className='button-title'>AWESOME</span>
      </button>
    </SidebarWidget>


React.Component.include.call ConnectedManagedMachineWidget, [KDReactorMixin]
