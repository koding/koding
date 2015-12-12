kd = require 'kd'
React = require 'kd-react'
ReactDOM = require 'react-dom'
Link = require 'app/components/common/link'
whoami = require 'app/util/whoami'
AutoSizeTextarea     = require 'app/components/common/autosizetextarea'
Avatar               = require 'app/components/profile/avatar'
ProfileLinkContainer = require 'app/components/profile/profilelinkcontainer'
ActivityFlux         = require 'activity/flux'
classnames           = require 'classnames'

module.exports = class CommentInputWidget extends React.Component

  constructor: (props) ->

    super

    @state =
      focusOnInput : no


  onFocus: (event) -> @setState focusOnInput: yes


  onBlur: (event) -> @setState focusOnInput: no


  getPostButtonClassNames: -> classnames
    'FeedItem-postComment' : yes
    'green'                : @state.hasValue
    'hidden'               : not @state.focusOnInput and not @state.hasValue


  render: ->

    imAccount   = { id: whoami()._id, constructorName: 'JAccount'}

    <div className='FeedItem-commentForm'>
      <div className="MediaObject-media">
        <ProfileLinkContainer origin={imAccount}>
          <Avatar className="FeedItem-Avatar" width={35} height={35} />
        </ProfileLinkContainer>
      </div>
      <AutoSizeTextarea
        ref         = 'textInput'
        onFocus     = { @bound 'onFocus' }
        onBlur      = { @bound 'onBlur' }
        placeholder = 'Type your comment'
        onChange    = { @props.handleCommentInputChange }
        value       = { @props.commentValue }
        className   = 'FeedItem-commentInput'/>
      <button
        className={@getPostButtonClassNames()}
        onClick={ @props.postComment }>SEND</button>
    </div>

