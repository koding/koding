React               = require 'kd-react'
ProfileText         = require './profiletext'
ProfileFetcherMixin = require './profilefetchermixin'

module.exports = class ProfileTextContainer extends React.Component

  @include [ProfileFetcherMixin]

  render: ->
    <ProfileText account={@state.account} {...@props} />
