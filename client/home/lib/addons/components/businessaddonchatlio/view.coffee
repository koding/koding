React = require 'app/react'
CustomerFeedBackView = require '../../../integrations/components/customerfeedback'
BusinessAddOnSectionOverlay = require 'lab/BusinessAddOnSectionOverlay'

module.exports = class BusinessAddOnChatlio extends React.Component

  getBusinessAddOnState: ->

    # Do it with Redux/Flux
    return no


  handleActivationButtonClick: ->

    # It will set state to show Activation Modal with Redux/Flux
    console.log('show activation modal')


  render: ->
    <div>
      <CustomerFeedBackView.Container />
      { <BusinessAddOnSectionOverlay onClick={@bound 'handleActivationButtonClick'} /> if not @getBusinessAddOnState() }
    </div>
