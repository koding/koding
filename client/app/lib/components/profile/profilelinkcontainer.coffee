React        = require 'app/react'
fetchAccount = require 'app/util/fetchAccount'
helper       = require './helper'

ProfileLink = require './profilelink'

module.exports = class ProfileLinkContainer extends React.Component

  constructor: (props) ->

    super props

    @state = { account: @props.account or helper.defaultAccount() }


  componentDidMount: ->

    if @props.origin
      fetchAccount @props.origin, (err, account) =>
        @setState { err, account }


  renderChildren: ->

    React.Children.map @props.children, (child) =>
      React.cloneElement child, { account: @state.account }


  render: ->
    <ProfileLink account={@state.account} {...@props}>
      {@renderChildren()}
    </ProfileLink>



