$                    = require 'jquery'
React                = require 'kd-react'
ReactDOM             = require 'react-dom'
formatContent        = require 'app/util/formatReactivityContent'
immutable            = require 'immutable'
classnames           = require 'classnames'
transformTags        = require 'app/util/transformReactivityTags'
ImmutableRenderMixin = require 'react-immutable-render-mixin'
renderEmojis         = require 'activity/util/renderEmojis'


module.exports = class MessageBody extends React.Component

  @include [ImmutableRenderMixin]

  @defaultProps =
    message: immutable.Map()


  constructor: (props) ->

    super props

    @state = { message: @props.message }


  componentDidMount: ->

    @transformChannelHashtags @state.message


  contentDidMount: (content) ->

    @content = content
    @renderEmojis()


  componentDidUpdate: (prevProps, prevState) ->

    { message } = @props

    # if message body is updated in props, we need to process hashtags
    # and update state with a new message body
    unless prevProps.message.get('body') is message.get('body')
      return @transformChannelHashtags message

    @renderEmojis()


  renderEmojis: ->

    contentElement = ReactDOM.findDOMNode @content
    renderEmojis contentElement  if contentElement


  transformChannelHashtags: (message) ->

    return  if message.has('isFake')
    return  unless message.has('body')

    transformTags message.get('body'), (transformed) =>

      @setState { message: message.set 'body', transformed }


  render: ->

    { message } = @state

    body    = helper.prepareMessageBody message.toJS()
    content = formatContent body

    typeConstant = message.get 'typeConstant'
    className    = classnames
      'has-markdown'          : yes
      'MessageBody'           : yes
      'MessageBody-joinLeave' : typeConstant in [ 'join', 'leave', 'system' ]

    return \
      <article
        className={className}
        ref={@bound 'contentDidMount'}
        dangerouslySetInnerHTML={__html: content} />


  helper =

    prepareDefaultBody: (options = {}) ->

      { addedBy, paneType, initialParticipants, action } = options

      # when it contains initial participants it contains all the accounts
      # initially added to the conversation
      if initialParticipants
        body = "has started the #{paneType}"

        return body  if initialParticipants.length is 0

        body = "#{body} and invited "
        body = "#{body} @#{participant}," for participant in initialParticipants

        return body.slice 0, body.length - 1

      body = "has #{action} the #{paneType}"

      # append who added the user
      body = "#{body} from an invitation by @#{addedBy}"  if addedBy

      return body


    prepareMessageBody: (message) ->

      { typeConstant, payload } = message

      {addedBy, initialParticipants, systemType} = payload if payload
      typeConstant = systemType  if typeConstant is 'system'

      paneType = 'conversation'

      options = { addedBy, paneType, initialParticipants }

      # get default join/leave message body
      switch typeConstant
        when 'join'
          options.action = 'joined'
          body = helper.prepareDefaultBody options
        when 'leave'
          options.action = 'left'
          body = helper.prepareDefaultBody options
        when 'invite'
          body = "was invited to the #{paneType}"
        when 'reject'
          body = "has rejected the invite for this #{paneType}"
        when 'kick'
          body = "has been removed from this #{paneType}"
        when 'initiate'
          body = helper.prepareDefaultBody options
        else
          body = message.body

      return body

