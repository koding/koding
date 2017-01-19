React = require 'app/react'
TryOnKoding = require '../../../../utilities/components/tryonkoding'
BusinessAddOnSectionOverlay = require 'lab/BusinessAddOnSectionOverlay'

class BusinessAddOnKodingButton extends React.Component

  handleActivationButtonClick: ->

    @props.onActivationButtonClick()


  render: ->

    <div>
      <header id='koding-button' className='HomeAppView--sectionHeader'>
        <a href='#koding-button'>Koding Button</a>
      </header>
      <section className='HomeAppView--section koding-button'>
        <TryOnKoding.Container />
        { <BusinessAddOnSectionOverlay onClick={@bound 'handleActivationButtonClick'} /> unless @props.addonStatus }
      </section>
    </div>


  module.exports = BusinessAddOnKodingButton
