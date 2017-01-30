React = require 'app/react'
CustomerFeedBackView = require '../../../../integrations/components/customerfeedback'
BusinessAddOnSectionOverlay = require 'lab/BusinessAddOnSectionOverlay'

class BusinessAddOnChatlio extends React.Component

  handleActivationButtonClick: ->

    @props.onActivationButtonClick()


  render: ->

    <div>
      <header id='chatlio' className='HomeAppView--sectionHeader'>
        <a href='#chatlio'>Chatlio</a>
      </header>
      <section className='HomeAppView--section customer-feedback'>
        <CustomerFeedBackView.Container />
        { <BusinessAddOnSectionOverlay onClick={@bound 'handleActivationButtonClick'} /> unless @props.addonStatus }
      </section>
    </div>


  module.exports = BusinessAddOnChatlio
