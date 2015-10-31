_                                 = require 'lodash'
kd                                = require 'kd'
Link                              = require 'app/components/common/link'
React                             = require 'kd-react'
Portal                            = require 'react-portal'
Avatar                            = require 'app/components/profile/avatar'
whoami                            = require 'app/util/whoami'
AppFlux                           = require 'app/flux'
TextArea                          = require 'react-autosize-textarea'
classnames                        = require 'classnames'
toImmutable                       = require 'app/util/toImmutable'
KeyboardKeys                      = require 'app/util/keyboardKeys'
ActivityFlux                      = require 'activity/flux'
ActivityModal                     = require 'app/components/activitymodal'
KDReactorMixin                    = require 'app/flux/base/reactormixin'
isPublicChannel                   = require 'app/util/isPublicChannel'
DropboxInputMixin                 = require 'activity/components/dropbox/dropboxinputmixin'
CreateChannelFlux                 = require 'activity/flux/createchannel'
ProfileLinkContainer              = require 'app/components/profile/profilelinkcontainer'
PreExistingChannelBox             = require './preexistingchannelbox'
ChannelParticipantsDropdown       = require 'activity/components/channelparticipantsdropdown'
CreateChannelParticipantsDropdown = require 'activity/components/createchannelparticipantsdropdown'

module.exports = class CreatePrivateChannelModal extends React.Component

  constructor: (props) ->

    super

    @state =
      name                : ''
      purpose             : ''
      query               : ''
      deleteMode          : no
      invalidParticipants : no
      placeholder         : 'type a @username and hit enter'
      preExistingChannel  : null


  componentDidMount: ->

    @focusOnParticipantsInput()


  componentWillUnmount: ->

    CreateChannelFlux.actions.user.resetSelectedIndex()
    CreateChannelFlux.actions.user.unsetInputQuery()
    CreateChannelFlux.actions.channel.removeAllParticipants()


  componentDidUpdate: (oldProps, oldState) ->

    if oldState.participants isnt @state.participants

      unless @state.participants?.size
        return @setState { preExistingChannel: null }

      participants = @state.participants
        .map (participant) -> participant.get 'socialApiId'
        .toList()
        .toJS()

      mySocialId = whoami().socialApiId

      # if there is only one participant and that one participant is me, then
      # don't show pre existing channel.
      if participants.length is 1 and participants[0] is mySocialId
        return @setState { preExistingChannel: null }

      { loadChannelByParticipants } = ActivityFlux.actions.channel

      loadChannelByParticipants(participants).then ({ channels }) =>
        if channels.length
          @setState { preExistingChannel: toImmutable channels[0] }
        else
          @setState { preExistingChannel: null }


  getDataBindings: ->

    { getters } = CreateChannelFlux

    return {
      participants        : getters.createChannelParticipants
      query               : getters.createChannelParticipantsSearchQuery
      dropdownUsers       : getters.createChannelParticipantsInputUsers
      selectedItem        : getters.createChannelParticipantsSelectedItem
      selectedIndex       : getters.createChannelParticipantsSelectedIndex
      dropdownVisibility  : getters.createChannelParticipantsDropdownVisibility
      selectedThread      : ActivityFlux.getters.selectedChannelThread
    }


  getDefaultPlaceholder: -> 'type a @username and hit enter'


  getParticipantsWrapperClassnames: -> classnames
    'delete-mode'                       : @state.deleteMode
    'CreateChannel-participantsWrapper' : yes


  getDropboxFieldClassnames: -> classnames
    'Reactivity-formfield' : yes
    'dropdown'             : yes
    'invalid'              : @state.invalidParticipants


  getModalProps: ->
    props =
      isOpen             : yes
      title              : 'Create a Private Conversation'
      className          : 'CreateChannel-Modal'
      buttonConfirmTitle : 'CREATE'
      onClose            : @bound 'onClose'
      onAbort            : @bound 'onClose'

    continueButtonTitle = 'CONTINUE EXISTING CONVERSATION'
    continueButtonOnClick = (event) =>
      kd.utils.stopDOMEvent event
      @_isRouting = yes
      kd.singletons.router.handleRoute "/Messages/#{@state.preExistingChannel.get 'id'}"

    createButtonTitle = 'CREATE'

    if @state.preExistingChannel
      if @state.name or @state.purpose
        props = _.assign {}, props,
          buttonExtraTitle       : continueButtonTitle
          onButtonExtraClick     : continueButtonOnClick
          buttonConfirmTitle     : createButtonTitle
          buttonConfirmClassName : 'Button--cancel'
          onConfirm              : @bound 'createChannel'
      else
        props = _.assign {}, props,
          buttonConfirmTitle : continueButtonTitle
          onConfirm          : continueButtonOnClick
    else
      props = _.assign {}, props,
        buttonExtraTitle       : null
        buttonConfirmTitle     : createButtonTitle
        onConfirm              : @bound 'createChannel'
        buttonConfirmClassName : 'Button--primary'

    return props


  setName: (event) ->

    value = event.target.value
    value = value.toLowerCase()
    @setState name: value


  setPurpose: (event) ->

    @setState purpose: event.target.value


  onClose: ->

    return  unless @state.selectedThread
    return  if @_isRouting

    channel = @state.selectedThread.get('channel').toJS()

    route = if isPublicChannel channel
    then "/Channels/#{channel.name}"
    else "/Messages/#{channel.id}"

    kd.singletons.router.handleRoute route


  prepareRecipients: ->

    @state.participants
      .toList()
      .map (p) -> p.getIn ['profile', 'nickname']
      .toJS()


  validateParticipants: ->

    recipients = @prepareRecipients()

    if recipients.length
      @setState invalidParticipants: no
      return yes
    else
      @setState invalidParticipants: yes
      return no


  createChannel: ->

    return  unless @validateParticipants()

    recipients = @prepareRecipients()
    options =
      name       : @state.name
      purpose    : @state.purpose
      recipients : recipients

    { createPrivateChannel } = CreateChannelFlux.actions.channel

    @_isRouting = yes

    createPrivateChannel(options)
      .then ({channel}) ->
        kd.singletons.router.handleRoute "/Messages/#{channel.id}"
      .catch =>
        @_isRouting = no


  onChange: (event) ->

    { value } = event.target
    @setState { value }

    matchResult = value.match /^@(.*)/

    query = value
    query = matchResult[1]  if matchResult

    { user } = CreateChannelFlux.actions

    user.setInputQuery query
    user.setDropdownVisibility yes

    if @state.participants.size
      accountId = @state.participants.last().get '_id'
      AppFlux.actions.user.unmarkParticipantMayBeDeleted accountId
      @setState
        deleteMode: no
        placeholder: @getDefaultPlaceholder()


  onBackspace: (event) ->

    { query  } = @state

    return yes  if query

    kd.utils.stopDOMEvent event

    return  unless @state.participants.size

    lastParticipant = @state.participants.last()
    accountId       = lastParticipant.get '_id'

    if lastParticipant.get '_mayDelete'
      CreateChannelFlux.actions.channel.removeParticipant accountId
      AppFlux.actions.user.unmarkParticipantMayBeDeleted accountId
      @setState
        deleteMode: no
        placeholder: @getDefaultPlaceholder()
    else
      AppFlux.actions.user.markParticipantMayBeDeleted accountId
      @setState
        deleteMode: yes
        placeholder: "Hit backspace again to remove #{lastParticipant.getIn ['profile', 'nickname']}"

    kd.utils.wait 100, => @validateParticipants()


  onDropdownItemConfirmed: (item) ->

    participant = @state.selectedItem

    { channel } = CreateChannelFlux.actions

    channel.addParticipant participant.get '_id'

    @setState query: ''
    @setState invalidParticipants: no
    @focusOnParticipantsInput()


  focusOnParticipantsInput: ->

    element = React.findDOMNode @refs.textInput
    element.focus()


  onInputKeydown: (event) ->

    { ENTER } = KeyboardKeys

    if event.which == ENTER
      @createChannel()


  renderNickname: (participant, isNicknameVisible)->

    nickname = participant.getIn ['profile', 'nickname']
    <span>{nickname}</span>


  renderParticipants: ->

    @state.participants.toList().map (participant) =>
      singleBoxClassName = if participant.get '_mayDelete'
      then 'ChannelParticipantAvatars-singleBox selected'
      else 'ChannelParticipantAvatars-singleBox'
      <div key={participant.get '_id'} className={singleBoxClassName}>
        <ProfileLinkContainer account={participant.toJS()}>
          <div>
            <Avatar
              className='ChannelParticipantAvatars-avatar'
              width={30}
              account={participant.toJS()}
              height={30} />
            {@renderNickname participant }
          </div>
        </ProfileLinkContainer>
      </div>


  renderAddParticipantInput: ->

    <div className={@getParticipantsWrapperClassnames()}>
      <div
        className='CreateChannel-participants'
        ref='CreateChannelParticipantsContainer'>
        {@renderParticipants()}
      </div>
      <input
        ref='CreateChannelParticipantsInput'
        onKeyDown   = { @bound 'onKeyDown' }
        onChange    = { @bound 'onChange' }
        placeholder = { @state.placeholder }
        value       = { @state.query }
        ref         = 'textInput'
        tabIndex    = 1
        autoFocus   = yes
        className   = {'Reactivity-input'}
      />
      {@renderAddNewChannelParticipantsDropdown()}
    </div>


  renderAddNewChannelParticipantsDropdown: ->

    <CreateChannelParticipantsDropdown
      ref             = 'dropdown'
      query           = { @state.query }
      value           = { @state.value }
      visible         = { @state.dropdownVisibility }
      items           = { @state.dropdownUsers }
      selectedItem    = { @state.selectedItem }
      selectedIndex   = { @state.selectedIndex }
      onItemConfirmed = { @bound 'onDropdownItemConfirmed' }
    />


  renderPreExistingChannelBox: ->

    return null  unless @state.preExistingChannel

    <PreExistingChannelBox
      participants={@state.participants}
      channel={@state.preExistingChannel} />


  render: ->

    <ActivityModal {...@getModalProps()}>
      <div className='CreateChannel-content'>
        <div className='CreateChannel-description'>
          <strong>
            A private conversation is only visible to its members,
            and only those members can read or search its contents.
          </strong>
          <div>{@props.extraInformation}</div>
        </div>
        <div className={@getDropboxFieldClassnames()}>
          <label className='Reactivity-label inviteMembers'>Invite Members</label>
          {@renderAddParticipantInput()}
        </div>
        {@renderPreExistingChannelBox()}
        <div className='Reactivity-formfield'>
          <label className='Reactivity-label channelName'>
            Name
            <span className='Reactivity-notRequired'> (optional)</span>
          </label>
          <input tabIndex=2 className='Reactivity-input' value={@state.name} maxlength='20' onChange={@bound 'setName'} onKeyDown={@bound 'onInputKeydown'}/>
          <span className='Reactivity-fieldMessage'>
            This is how this conversation is going to appear on your sidebar.
          </span>
        </div>
        <div className='Reactivity-formfield'>
          <label className='Reactivity-label channelPurpose'>
            Purpose
            <span className='Reactivity-notRequired'> (optional)</span>
          </label>
          <input tabIndex=3 className='Reactivity-input' value={@state.purpose} maxlength='200' onChange={@bound 'setPurpose'} onKeyDown={@bound 'onInputKeydown'}/>
          <span className='Reactivity-fieldMessage'>
            Set a purpose to your conversation that describes what it will be used for.
          </span>
        </div>
      </div>
    </ActivityModal>


React.Component.include.call CreatePrivateChannelModal, [KDReactorMixin, DropboxInputMixin]

