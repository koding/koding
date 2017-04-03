React               = require 'app/react'
ProfileLink         = require './profilelink'
ProfileFetcherMixin = require './profilefetchermixin'

module.exports = class ProfileLinkContainer extends React.Component

  @include [ProfileFetcherMixin]

  render: ->
    <ProfileLink {...@props}>
      {@renderChildren()}
    </ProfileLink>
