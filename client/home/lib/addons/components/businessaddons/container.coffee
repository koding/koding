React = require 'react'
{ connect } = require 'react-redux'
addon = require 'app/redux/modules/payment/addon'
BusinessAddons = require './view'

mapStateToProps = (state) ->
  return {
    addonStatus: addon.isActivated state
    addonPrice: addon.getAddonPrice state
    # kodingButtonStatus: addon.isKodingButtonActivated state
    # intercomStatus: addon.isIntercomActivated state
  }

mapDispatchToProps = (dispatch) ->
  return {
    onActivateBusinessAddOn: -> dispatch(addon.create())
    onDeactivateBusinessAddOn: -> dispatch(addon.remove())
    # onActiveKodingButton: -> dispatch(addon.activeKodingButton())
    # onActiveIntercom: -> dispatch(addon.activeIntercom())
    # onActiveChatlio: -> dispatch(addon.activeChatlio())
  }

module.exports = connect(
  mapStateToProps
  mapDispatchToProps
)(BusinessAddons)
