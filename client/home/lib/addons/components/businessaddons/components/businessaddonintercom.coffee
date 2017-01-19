React = require 'app/react'
IntercomIntegration = require '../../../../integrations/components/intercomintegration'
BusinessAddOnSectionOverlay = require 'lab/BusinessAddOnSectionOverlay'

class BusinessAddOnIntercom extends React.Component

  handleActivationButtonClick: ->

    @props.onActivationButtonClick()


  render: ->

    <div>
      <header id='intercom' className='HomeAppView--sectionHeader'>
        <a href='#intercom'>Intercom</a>
      </header>
      <section className='HomeAppView--section intercom-integration'>
        <IntercomIntegration.Container />
        { <BusinessAddOnSectionOverlay onClick={@bound 'handleActivationButtonClick'} /> unless @props.addonStatus }
      </section>
    </div>


  module.exports = BusinessAddOnIntercom
