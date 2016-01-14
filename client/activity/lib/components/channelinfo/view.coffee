kd                   = require 'kd'
React                = require 'kd-react'
moment               = require 'moment'
immutable            = require 'immutable'
classnames           = require 'classnames'
whoami               = require 'app/util/whoami'
Link                 = require 'app/components/common/link'
ProfileText          = require 'app/components/profile/profiletext'
ProfileLinkContainer = require 'app/components/profile/profilelinkcontainer'

module.exports = class ChannelInfoView extends React.Component

  @propTypes =
    channel                   : React.PropTypes.instanceOf immutable.Map
    onInviteClick             : React.PropTypes.func.isRequired
    onIntegrationClick        : React.PropTypes.func.isRequired
    onCollaborationClick      : React.PropTypes.func.isRequired
    collabTooltipVisible      : React.PropTypes.bool
    integrationTooltipVisible : React.PropTypes.bool


  @defaultProps =
    channel                   : immutable.Map()
    collabTooltipVisible      : no
    integrationTooltipVisible : no


  renderChannelName: ->

    switch @props.channel.get 'typeConstant'
      when 'bot'
        <div className='ChannelInfoContainer-name'>
          <strong>Koding Bot</strong>
        </div>
      when 'privatemessage', 'collaboration'
        <div className='ChannelInfoContainer-name'>
          This is a <strong>private</strong> conversation.
        </div>
      when 'topic'
        <div className='ChannelInfoContainer-name'>
          #{@props.channel.get 'name'}
        </div>


  renderProfileLink: ->

    authorId = @props.channel.get 'accountOldId'
    origin = { _id: authorId, constructorName: 'JAccount' }

    author = if authorId is whoami()._id
      <strong>you</strong>
    else
      <ProfileLinkContainer origin={origin}>
        <ProfileText />
      </ProfileLinkContainer>

    dateString = moment(@props.channel.get 'createdAt').calendar null,
      sameDay  : '[today]'
      lastDay  : '[yesterday]'
      lastWeek : '[last] dddd'
      sameElse : '[on] MMM D'

    return \
      <span className='ChannelInfoContainer-profileLink'>
        , created by {author} {dateString}.<br/>
      </span>


  renderChannelIntro: ->

    channelName = @props.channel.get 'name'

    switch @props.channel.get 'typeConstant'
      when 'bot'
        <span>
          This is the very beginning of your chat history with <strong>Koding Bot</strong>. He is not so smart :)
        </span>
      when 'privatemessage'
        null
      when 'topic'
        <span>
          This is the <Link onClick=kd.noop>#{channelName}</Link> channel {@renderProfileLink()}
        </span>


  render: ->

    <div className='ChannelInfoContainer'>
      {@renderChannelName()}
      <div className='ChannelInfoContainer-description'>
        {@renderChannelIntro()}
        <div>
          You can start a collaboration session, or drag and drop VMs and
          workspaces here from the sidebar to let anyone in this channel access
          them.
          (<Link onClick ={@props.onCollaborationClick}>Show me how?</Link>)
        </div>
      </div>
      <div className='ChannelInfoContainer-actions'>
        <Link
          className='ChannelInfoContainer-action StartCollaborationLink'
          onClick={@props.onCollaborationClick}>
          Start Collaboration
          {renderTooltip @props.collabTooltipVisible}
        </Link>
        <Link
          className='ChannelInfoContainer-action AddIntegrationLink'
          onClick={@props.onIntegrationClick}>
          Add integration
          {renderTooltip @props.integrationTooltipVisible}
        </Link>
        <Link
          className='ChannelInfoContainer-action InviteOthersLink'
          onClick={@props.onInviteClick}>
          Invite others
        </Link>
      </div>
    </div>


renderTooltip = (state) ->

  className = classnames
    'Tooltip-wrapper' : yes
    'visible'         : state

  <div className={className}>
    <span>Coming soon</span>
  </div>

