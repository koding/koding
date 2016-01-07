kd    = require 'kd'
React = require 'kd-react'
Link  = require 'app/components/common/link'

module.exports = class SocialShareLinkItem extends React.Component

  @defaultProps=
    href     : ''
    provider : ''
    onClick  : kd.noop


  onClick: (event) ->

    kd.utils.stopDOMEvent event

    { onClick, href, provider } = @props

    onClick href, provider


  render: ->

    <Link {...@props} onClick={@bound 'onClick'} />
