kd = require 'kd'
React = require 'app/react'
SidebarWidget = require './widget'


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

  onClose: ->

    kd.singletons.sidebar.removeManaged @props.machine.getId()


  onButtonClick: ->

    kd.singletons.router.handleRoute newPath

    @onClose()


  render: ->

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
            onClick={@bound 'onButtonClick'}
            children='START CODING' />

        </div>
      </div>

    </SidebarWidget>
