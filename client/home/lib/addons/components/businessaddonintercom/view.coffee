React = require 'app/react'
IntercomIntegration = require '../../../integrations/components/intercomintegration'
BusinessAddOnSectionOverlay = require 'lab/BusinessAddOnSectionOverlay'
{ connect } = require 'react-redux'
addon = require 'app/redux/modules/payment/addon'

class BusinessAddOnIntercom extends React.Component

  handleActivationButtonClick: ->

    @props.toggleModal()


  render: ->

    <div>
      <IntercomIntegration.Container />
      { <BusinessAddOnSectionOverlay onClick={@bound 'handleActivationButtonClick'} />  unless @props.addonStatus }
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
  )(BusinessAddOnIntercom)
