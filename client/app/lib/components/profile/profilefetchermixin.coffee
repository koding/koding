React = require 'kd-react'
helper = require './helper'
fetchAccount = require 'app/util/fetchAccount'

module.exports =
  getInitialState: ->
    return {
      account: @props.account or helper.defaultAccount()
    }

  componentDidMount: ->
    if @props.origin
      fetchAccount @props.origin, (err, account) =>
        @setState { err, account }


  renderChildren: ->
    React.Children.map @props.children, (child) =>
      React.cloneElement child, { account: @state.account }
