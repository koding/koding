kd           = require 'kd'
React        = require 'kd-react'
helper       = require './helper'
fetchAccount = require 'app/util/fetchAccount'

module.exports = class ProfileLink extends React.Component

  @defaultProps =
    onClick  : kd.noop


  getHref: -> "/#{@props.account.profile.nickname}"


  render: ->
    <a href={@getHref()} onClick={@props.onClick} {...@props}>
      {@props.children}
    </a>



