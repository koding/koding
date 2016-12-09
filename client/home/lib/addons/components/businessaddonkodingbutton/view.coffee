React = require 'app/react'
TryOnKoding = require '../../../utilities/components/tryonkoding'
BusinessAddOnSectionOverlay = require 'lab/BusinessAddOnSectionOverlay'

module.exports = class BusinessAddOnKodingButton extends React.Component

  getBusinessAddOnState: ->

    # Do it with Redux/Flux
    return no


  handleActivationButtonClick: ->

    # It will set state to show Activation Modal with Redux/Flux
    console.log('show activation modal')


  render: ->
    <div>
      <TryOnKoding.Container />
      { <BusinessAddOnSectionOverlay onClick={@bound 'handleActivationButtonClick'} /> if not @getBusinessAddOnState() }
    </div>
