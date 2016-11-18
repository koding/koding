React = require 'app/react'
helper = require './helper'
fetchAccount = require 'app/util/fetchAccount'

module.exports = ProfileFetcherMixin =


  getInitialState: ->

    account = if @props.origin?.isIntegration
    then @props.origin
    else @props.account

    return {
      account: account or helper.defaultAccount()
    }


  componentDidMount: ->

    @_isMounted = yes

    if @props.origin
      if @props.origin.isIntegration
        @setState { account: @props.origin }
      else
        fetchAccount @props.origin, (err, account) =>
          return  unless @_isMounted
          @setState { err, account }


  componentWillUnmount: -> @_isMounted = no


  renderChildren: ->
    React.Children.map @props.children, (child) =>
      React.cloneElement child, { account: @state.account }
