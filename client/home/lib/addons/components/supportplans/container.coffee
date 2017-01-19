React = require 'react'
{ connect } = require 'react-redux'
supportplans = require 'app/redux/modules/payment/supportplans'
SupportPlans = require './view'

mapStateToProps = (state) ->
  return {
    plans: supportplans.getAllSupportPlans state
    activeSupportPlan: supportplans.getActiveSupportPlan state
  }

mapDispatchToProps = (dispatch) ->
  return {
    onActivateSupportPlan: (plan) -> dispatch(supportplans.create plan)
    onUpdateSupportPlan: (plan) -> dispatch(supportplans.update plan)
    onDeactivateSupportPlan: -> dispatch(supportplans.remove())
  }

module.exports = connect(
  mapStateToProps
  mapDispatchToProps
)(SupportPlans)
