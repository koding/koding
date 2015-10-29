React = require 'kd-react'
helper = require './helper'
fetchAccount = require 'app/util/fetchAccount'

module.exports =


  getInitialState: ->

    account = if @props.origin?.isIntegration
    then @props.origin
    else @props.account

    return {
      account: account or helper.defaultAccount()
    }


  componentDidMount: ->

    if @props.origin
      if @props.origin.isIntegration
        @setState { account: @props.origin }
      else
        fetchAccount @props.origin, (err, account) =>
          @setState { err, account }


  renderChildren: ->
    React.Children.map @props.children, (child) =>
      React.cloneElement child, { account: @state.account }
