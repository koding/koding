kd                   = require 'kd'
React                = require 'kd-react'
generateDummyMessage = require 'app/util/generateDummyMessage'
ProfileLinkContainer = require 'app/components/profile/profilelinkcontainer'
ProfileText          = require 'app/components/profile/profiletext'
Avatar               = require 'app/components/profile/avatar'
TimeAgo              = require 'app/components/common/timeago'
toImmutable          = require 'app/util/toImmutable'
Link                 = require 'app/components/common/link'
MessageBody          = require 'activity/components/common/messagebody'


module.exports = class FeedInputWidgetPreview extends React.Component

  defaultProps=
    value                     : ''
    previewMode               : no
    toggleMarkdownPreviewMode : kd.noop


  render: ->

    return null  unless @props.previewMode

    message = toImmutable generateDummyMessage @props.value
    message = message.set 'isPreview', yes

    <div className='FeedInputWidget-previewWrapper MediaObject'>
      <Link
        onClick={@props.toggleMarkdownPreviewMode}
        className='FeedInputWidget-closePreview'>
        Previewing
      </Link>
      <div className='MediaObject-media'>
        <ProfileLinkContainer origin={message.get('account').toJS()}>
          <Avatar width={35} height={35} />
        </ProfileLinkContainer>
      </div>
      <ProfileLinkContainer key={message.getIn(['account', 'id'])} origin={message.get('account').toJS()}>
        <ProfileText />
      </ProfileLinkContainer>
      <div className='FeedInputWidget-previewDate'>
        <TimeAgo from={message.get 'createdAt'} className='FeedItem-date'/>
      </div>
      <div className='FeedInputWidget-previewBody'>
        <MessageBody message={message}/>
      </div>
    </div>
