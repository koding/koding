kd           = require 'kd'
React        = require 'kd-react'
Link         = require 'app/components/common/link'
ActivityFlux = require 'activity/flux'

module.exports = class SocialShareLink extends React.Component

  @defaultProps =
    messageId: null


  componentDidMount: ->

    kd.utils.defer =>
      ActivityFlux.actions.feed.setFeedListItem @props.messageId, this


  componentWillUnmount: ->

    kd.utils.defer =>
       ActivityFlux.actions.feed.unsetFeedListItem @props.messageId, this


  setActiveSocialShareLink: ->

    ActivityFlux.actions.feed.setActiveSocialShareLink @props.messageId


  render: ->

    <Link onClick={@bound 'setActiveSocialShareLink'}>Share</Link>

