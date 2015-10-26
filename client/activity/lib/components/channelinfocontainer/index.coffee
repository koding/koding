kd                   = require 'kd'
React                = require 'kd-react'
classnames           = require 'classnames'
whoami               = require 'app/util/whoami'
Link                 = require 'app/components/common/link'
ProfileLinkContainer = require 'app/components/profile/profilelinkcontainer'
ProfileText          = require 'app/components/profile/profiletext'
moment               = require 'moment'
immutable            = require 'immutable'


module.exports = class ChannelInfoContainer extends React.Component

  @defaultProps =
    onInviteOthers: kd.noop
    thread: immutable.Map()


  constructor: (props) ->

    super props

    @state = { collabTooltipVisible: no, integrationTooltipVisible: no }


  channel: (key) -> @props.thread?.getIn ['channel', key]


  onCollaborationHelp: (event) ->

    kd.utils.stopDOMEvent event

    @setState collabTooltipVisible: yes

    kd.utils.wait 2000, => @setState collabTooltipVisible: no


  onIntegrationHelp: (event) ->

    kd.utils.stopDOMEvent event

    @setState integrationTooltipVisible: yes

    kd.utils.wait 2000, => @setState integrationTooltipVisible: no


  onInviteOthers: (event) ->

    kd.utils.stopDOMEvent event

    @props.onInviteOthers?()


  renderChannelName: ->

    switch @channel 'typeConstant'
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
          #{@channel 'name'}
        </div>


  renderProfileLink: ->

    authorId = @channel 'accountOldId'
    origin = { _id: authorId, constructorName: 'JAccount' }

    author = if authorId is whoami()._id
      <strong>you</strong>
    else
      <ProfileLinkContainer origin={origin}>
        <ProfileText />
      </ProfileLinkContainer>

    dateString = moment(@channel 'createdAt').calendar null,
      sameDay  : '[today]'
      lastDay  : '[yesterday]'
      lastWeek : '[last] dddd'
      sameElse : '[on] MMM D'

    return \
      <span>
        , created by {author} {dateString}.<br/>
      </span>


  renderChannelIntro: ->

    channelName = @channel 'name'

    switch @channel 'typeConstant'
      when 'bot'
        [
          "This is the very beginning of your chat history with"
          <strong>Koding Bot</strong>
          ". He is not so smart :)"
        ]
      when 'privatemessage'
        null
      when 'topic'
        [
          "This is the "
          <Link onClick=kd.noop>#{channelName}</Link>
          " channel"
          @renderProfileLink()
        ]


  render: ->
    <div className='ChannelInfoContainer'>
      {@renderChannelName()}
      <div className='ChannelInfoContainer-description'>
        {@renderChannelIntro()}
        You can start a collaboration session, or drag and drop  VMs and
        workspaces here from the sidebar to let anyone in this channel access
        them.
        (<Link onClick ={@bound 'onCollaborationHelp'}>Show me how?</Link>)
      </div>
      <div className='ChannelInfoContainer-actions'>
        <Link
          className='ChannelInfoContainer-action StartCollaborationLink'
          onClick={@bound 'onCollaborationHelp'}>
          Start Collaboration
          {renderTooltip @state.collabTooltipVisible}
        </Link>
        <Link
          className='ChannelInfoContainer-action AddIntegrationLink'
          onClick={@bound 'onIntegrationHelp'}>
          Add integration
          {renderTooltip @state.integrationTooltipVisible}
        </Link>
        <Link
          className='ChannelInfoContainer-action InviteOthersLink'
          onClick={@bound 'onInviteOthers'}>
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


