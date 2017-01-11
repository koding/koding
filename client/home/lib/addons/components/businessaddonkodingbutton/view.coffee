React = require 'app/react'
TryOnKoding = require '../../../utilities/components/tryonkoding'
BusinessAddOnSectionOverlay = require 'lab/BusinessAddOnSectionOverlay'
{ connect } = require 'react-redux'
addon = require 'app/redux/modules/payment/addon'

class BusinessAddOnKodingButton extends React.Component

  handleActivationButtonClick: ->

    @props.toggleModal()


  render: ->

    <div>
      <TryOnKoding.Container />
      { <BusinessAddOnSectionOverlay onClick={@bound 'handleActivationButtonClick'} /> unless @props.addonStatus }
    </div>


  mapStateToProps = (state) ->

    return {
      addonStatus: addon.isActivated state
    }


  mapDispatchToProps = (dispatch) ->

    return {
      onActivateBusinessAddOn: ->
        dispatch(addon.create())
      toggleModal: ->
        dispatch(addon.toggleModal())
    }


  module.exports = connect(
    mapStateToProps
    mapDispatchToProps
  )(BusinessAddOnKodingButton)
