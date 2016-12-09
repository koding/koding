React = require 'app/react'
IntercomIntegration = require '../../../integrations/components/intercomintegration'
BusinessAddOnSectionOverlay = require 'lab/BusinessAddOnSectionOverlay'

module.exports = class BusinessAddOnIntercom extends React.Component

  getBusinessAddOnState: ->

    # Do it with Redux/Flux
    return no


  handleActivationButtonClick: ->

    # It will set state to show Activation Modal with Redux/Flux
    console.log('show activation modal')


  render: ->
    <div>
      <IntercomIntegration.Container />
      { <BusinessAddOnSectionOverlay onClick={@bound 'handleActivationButtonClick'} /> if not @getBusinessAddOnState() }
    </div>
