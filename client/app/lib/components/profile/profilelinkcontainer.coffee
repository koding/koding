React               = require 'kd-react'
ProfileLink         = require './profilelink'
ProfileFetcherMixin = require './profilefetchermixin'

module.exports = class ProfileLinkContainer extends React.Component

  @include [ProfileFetcherMixin]

  render: ->
    <ProfileLink account={@state.account} {...@props}>
      {@renderChildren()}
    </ProfileLink>
