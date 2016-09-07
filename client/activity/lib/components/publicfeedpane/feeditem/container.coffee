kd              = require 'kd'
View            = require './view'
React           = require 'kd-react'
immutable       = require 'immutable'
ActivityFlux    = require 'activity/flux'


module.exports = class FeedItemContainer extends React.Component

  @propTypes =

    key       : React.PropTypes.string
    message   : React.PropTypes.instanceOf immutable.Map
    channelId : React.PropTypes.string

  @defaultProps =

    key       : null
    message   : immutable.Map()
    channelId : null


  shouldComponentUpdate: (nextProps, nextState) ->

    return @props.message isnt nextProps.message or @state isnt nextState


  handleCommentLinkClick: (event) ->

    kd.utils.stopDOMEvent event

    @refs.view.refs.Comments.focusCommentInput()


  updateMessage: ->

    value     = @refs.view.refs.editInputWidget.getValue().trim()
    messageId = @props.message.get '_id'

    { message } = ActivityFlux.actions

    message.unsetMessageEditMode messageId, @props.channelId
    message.editMessage messageId, value


  cancelEdit: ->

    messageId = @props.message.get '_id'
    { message } = ActivityFlux.actions

    message.unsetMessageEditMode messageId, @props.channelId, yes


  render: ->

    <View
      ref                    = 'view'
      key                    = { @props.key }
      message                = { @props.message }
      channelId              = { @props.channelId }
      cancelEdit             = { @bound 'cancelEdit' }
      updateMessage          = { @bound 'updateMessage' }
      handleCommentLinkClick = { @bound 'handleCommentLinkClick' }/>