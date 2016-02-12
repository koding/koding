kd           = require 'kd'
React        = require 'kd-react'
ReactDOM     = require 'react-dom'
ActivityFlux = require 'activity/flux'
fetchAccount = require 'app/util/fetchAccount'
immutable    = require 'immutable'
View         = require './view'

module.exports = class CommentsContainer extends React.Component

  @propTypes =
    channelId : React.PropTypes.string
    message   : React.PropTypes.instanceOf immutable.Map


  @defaultProps =
    channelId : ''
    message   : immutable.Map()

  constructor: (props) ->

    super

    @state =
      hasValue     : no
      commentValue : ''
      focusOnInput : no


  componentDidMount: ->

    view       = ReactDOM.findDOMNode @refs.view
    @textInput = view.querySelector '.CommentInputWidget-input'


  onMentionClick: (reply) ->

    account   = reply.get 'account'

    fetchAccount account.toJS(), (err, account) =>
      return  unless account

      inputValue = if @textInput.value then "#{ @textInput.value} " else ""
      value      = "#{inputValue}@#{account.profile.nickname} "

      @setState { commentValue: value, hasValue: yes }, @bound 'focusCommentInput'


  focusCommentInput: -> @textInput.focus()


  postComment: (event) ->

    kd.utils.stopDOMEvent event

    ActivityFlux.actions.message.createComment @props.message.get('id'), @state.commentValue
      .then => @setState { commentValue: '', hasValue: no }


  handleCommentInputChange: (event) ->

    hasValue = no
    value    = event.target.value
    hasValue = yes  if value.trim()
    @setState { hasValue: hasValue, commentValue: value }


  getComments: ->

    comments = @props.message.get 'comments'

    return immutable.Map()  unless comments

    comments.sort (a, b) ->
      if a.get('createdAt') > b.get('createdAt') then 1
      else if a.get('createdAt') < b.get('createdAt') then return -1
      else 0


  render: ->

    <View
      ref            = 'view'
      comments       = { @getComments() }
      hasValue       = { @state.hasValue }
      channelId      = { @props.channelId }
      commentValue   = { @state.commentValue }
      postComment    = { @bound 'postComment' }
      onMentionClick = { @bound 'onMentionClick' }
      messageId      = { @props.message.get '_id' }
      onChange       = { @bound 'handleCommentInputChange' }
      repliesCount   = { @props.message.get 'repliesCount' }/>
