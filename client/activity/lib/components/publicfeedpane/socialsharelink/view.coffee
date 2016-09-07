kd           = require 'kd'
React        = require 'kd-react'
Link         = require 'app/components/common/link'


module.exports = class SocialShareLink extends React.Component

  @propTypes =
    setActiveSocialShareLink : React.PropTypes.func

  @defaultTypes =
    setActiveSocialShareLink : kd.noop


  render: ->

    <Link onClick={@props.setActiveSocialShareLink}>Share</Link>
