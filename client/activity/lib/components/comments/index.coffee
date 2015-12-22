kd                   = require 'kd'
React                = require 'kd-react'
ReactDOM             = require 'react-dom'
ActivityFlux         = require 'activity/flux'
classnames           = require 'classnames'
fetchAccount         = require 'app/util/fetchAccount'
immutable            = require 'immutable'
CommentList          = require './commentlist'
CommentInputWidget   = require './commentinputwidget'

module.exports = class Comments extends React.Component

  @defaultProps=
    message : immutable.Map()

  constructor: (props) ->

    super

    @state =
      hasValue     : no
      commentValue : ''
      focusOnInput : no


  componentDidMount: ->

    @textInput = ReactDOM.findDOMNode @refs.CommentInputWidget.refs.textInput


  onFocus: (event) -> @setState focusOnInput: yes


  onBlur: (event) -> @setState focusOnInput: no


  onMentionClick: (reply) ->

    kd.utils.stopDOMEvent event

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




  render: ->

    <div className='CommentsWrapper'>
      <CommentList
        repliesCount={ @props.message.get 'repliesCount' }
        comments={ @props.message.get 'replies' }
        onMentionClick={ @bound 'onMentionClick' } />
      <CommentInputWidget
        ref='CommentInputWidget'
        hasValue = { @state.hasValue }
        postComment={ @bound 'postComment' }
        commentValue={ @state.commentValue }
        handleCommentInputChange={ @bound 'handleCommentInputChange' } />
    </div>

