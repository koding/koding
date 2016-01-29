kd                   = require 'kd'
React                = require 'kd-react'
classnames           = require 'classnames'
whoami               = require 'app/util/whoami'
Avatar               = require 'app/components/profile/avatar'
AutoSizeTextarea     = require 'app/components/common/autosizetextarea'
ProfileLinkContainer = require 'app/components/profile/profilelinkcontainer'

module.exports = class CommentInputWidgetView extends React.Component

  @propTypes =
    hasValue     : React.PropTypes.bool
    focusOnInput : React.PropTypes.bool
    onChange     : React.PropTypes.func.isRequired
    onKeyDown    : React.PropTypes.func.isRequired
    onFocus      : React.PropTypes.func.isRequired
    onBlur       : React.PropTypes.func.isRequired
    postComment  : React.PropTypes.func.isRequired
    commentValue : React.PropTypes.string.isRequired


  @defaultProps =
    hasValue     : no


  getPostButtonClassNames: -> classnames
    'FeedItem-postComment' : yes
    'green'                : @props.hasValue
    'hidden'               : not @props.focusOnInput and not @props.hasValue


  onKeyDown: (event) ->

    if event.keyCode is 13 and event.metaKey
      @props.postComment()
      # event.preventDefault()
      # event.stopPropagation()

  render: ->
    console.log 'props ', @props
    imAccount   = { id: whoami()._id, constructorName: 'JAccount'}

    <div className='CommentInputWidget'>
      <div className="MediaObject-media">
        <ProfileLinkContainer origin={imAccount}>
          <Avatar width={35} height={35} />
        </ProfileLinkContainer>
      </div>
      <AutoSizeTextarea
        ref         = 'textInput'
        onFocus     = { @props.onFocus }
        onBlur      = { @props.onBlur }
        placeholder = 'Type your comment'
        onKeyDown   = { @bound 'onKeyDown' }
        onChange    = { @props.onChange }
        value       = { @props.commentValue }
        className   = 'CommentInputWidget-input'/>
      <button
        ref       = 'postComment'
        className = { @getPostButtonClassNames() }
        onClick   = { @props.postComment }>SEND</button>
    </div>
