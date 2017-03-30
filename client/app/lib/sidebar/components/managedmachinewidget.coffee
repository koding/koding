kd = require 'kd'
React = require 'app/react'
SidebarWidget = require './widget'
EnvironmentFlux = require 'app/flux/environment'
KDReactorMixin = require 'app/flux/base/reactormixin'
actions = require 'app/flux/environment/actions'


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


module.exports = class ManagedMachineWidget extends React.Component

  @defaultProps =
    className : 'ConnectedManagedVm sidebar-info-modal'

  getDataBindings: ->
    connectedManagedMachine: EnvironmentFlux.getters.connectedManagedMachine


  onClose: ->

    kd.utils.defer =>
      actions.hideManagedMachineAddedModal @props.machine.get '_id'


  handleButtonClick: ->

    { router } = kd.singletons
    currentPath = router.getCurrentPath()
    newPath = "/IDE/#{@props.machine.slug}"

    @onClose()
    router.handleRoute newPath  unless newPath is currentPath


  render: ->

    connectedMachine = @state.connectedManagedMachine.get @props.machine.get('_id')

    return null  unless connectedMachine

    provider = if PROVIDERS[connectedMachine.providerName]
    then connectedMachine.providerName
    else 'UnknownProvider'

    <SidebarWidget {...@props} onClose={@bound 'onClose'}>

      <div className='header'>
        <h1>Congratulations</h1>
      </div>
      <span className='close-icon' onClick={@bound 'onClose'} />
      <div className='main-wrapper'>
        <div className='image-wrapper' />
        <div className='content'>

          <div className='label'>Your machine is now connected!</div>

          <div className='description'>
            You may now use this machine just like you use your Koding VM. You
            can open files, terminals and even initiate collaboration session.
          </div>

          <button
            className='GenericButton'
            onClick={@bound 'handleButtonClick'}
            children='START CODING' />

        </div>
      </div>

    </SidebarWidget>


ManagedMachineWidget.include [KDReactorMixin]
