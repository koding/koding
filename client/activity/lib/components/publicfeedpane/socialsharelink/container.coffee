kd              = require 'kd'
View            = require './view'
React           = require 'kd-react'
ActivityFlux    = require 'activity/flux'


module.exports = class FeedPaneContainer extends React.Component

  @propTypes =
    messageId : React.PropTypes.string

  @defaultProps =
    messageId : null


  componentDidMount: ->

    kd.utils.defer =>
      ActivityFlux.actions.feed.setFeedListItem @props.messageId, this


  componentWillUnmount: ->

    kd.utils.defer =>
       ActivityFlux.actions.feed.unsetFeedListItem @props.messageId, this


  setActiveSocialShareLink: ->

    ActivityFlux.actions.feed.setActiveSocialShareLink @props.messageId

  render: ->

    <View
      setActiveSocialShareLink = { @bound 'setActiveSocialShareLink' }/>