React = require 'app/react'
{ connect } = require 'react-redux'
addon = require 'app/redux/modules/payment/addon'
PlanDeactivation = require '../plandeactivation'

class AddOnDeactivation extends React.Component

  constructor: (props) ->

    super props


  deactivateBusinessAddOn: () ->

    @props.onDeactivateBusinessAddOn()


  render: ->

    <div>
      {
        <PlanDeactivation.Container
          target='BUSINESS ADD-ON'
          onDeactivation={@bound 'deactivateBusinessAddOn'} />  if @props.addonStatus
      }
    </div>


  mapStateToProps = (state) ->

    return {
      addonStatus: addon.isActivated state
    }


  mapDispatchToProps = (dispatch) ->

    return {
      onDeactivateBusinessAddOn: ->
        dispatch(addon.remove())
    }


  module.exports = connect(
    mapStateToProps
    mapDispatchToProps
  )(AddOnDeactivation)
