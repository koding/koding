kd                   = require 'kd'
React                = require 'kd-react'
whoami               = require 'app/util/whoami'
AutoSizeTextarea     = require 'app/components/common/autosizetextarea'
Avatar               = require 'app/components/profile/avatar'
ProfileLinkContainer = require 'app/components/profile/profilelinkcontainer'
classnames           = require 'classnames'
KeyboardKeys         = require 'app/constants/keyboardKeys'

module.exports = class CommentInputWidget extends React.Component

  constructor: (props) ->

    super

    @state =
      focusOnInput : no


  onFocus: (event) -> @setState focusOnInput: yes


  onBlur: (event) -> @setState focusOnInput: no


  onKeyDown: (event) ->

    if event.which is KeyboardKeys.ESC
      @props.cancelEdit()


  getPostButtonClassNames: -> classnames
    'FeedItem-postComment' : yes
    'green'                : @props.hasValue
    'hidden'               : not @state.focusOnInput and not @props.hasValue


  render: ->

    imAccount   = { id: whoami()._id, constructorName: 'JAccount'}

    <div className='CommentInputWidget'>
      <div className="MediaObject-media">
        <ProfileLinkContainer origin={imAccount}>
          <Avatar width={35} height={35} />
        </ProfileLinkContainer>
      </div>
      <AutoSizeTextarea
        ref         = 'textInput'
        onFocus     = { @bound 'onFocus' }
        onBlur      = { @bound 'onBlur' }
        placeholder = 'Type your comment'
        onKeyDown   = { @bound 'onKeyDown' }
        onChange    = { @props.handleCommentInputChange }
        value       = { @props.commentValue }
        className   = 'CommentInputWidget-input'/>
      <button
        className={@getPostButtonClassNames()}
        onClick={ @props.postComment }>SEND</button>
    </div>

