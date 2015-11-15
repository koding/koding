kd                                = require 'kd'
Link                              = require 'app/components/common/link'
React                             = require 'kd-react'
Portal                            = require('react-portal').default
Avatar                            = require 'app/components/profile/avatar'
AppFlux                           = require 'app/flux'
classnames                        = require 'classnames'
KeyboardKeys                      = require 'app/util/keyboardKeys'
ActivityFlux                      = require 'activity/flux'
ActivityModal                     = require 'app/components/activitymodal'
KDReactorMixin                    = require 'app/flux/base/reactormixin'
isPublicChannel                   = require 'app/util/isPublicChannel'
DropboxInputMixin                 = require 'activity/components/dropbox/dropboxinputmixin'
CreateChannelFlux                 = require 'activity/flux/createchannel'
ProfileLinkContainer              = require 'app/components/profile/profilelinkcontainer'
ChannelParticipantsDropdown       = require 'activity/components/channelparticipantsdropdown'
CreateChannelParticipantsDropdown = require 'activity/components/createchannelparticipantsdropdown'

module.exports = class CreatePublicChannelModal extends React.Component


  @include [DropboxInputMixin]


  constructor: (props) ->

    super props

    @state =
      name                : ''
      purpose             : ''
      query               : ''
      deleteMode          : no
      invalidName         : no
      invalidParticipants : no
      placeholder         : 'type a @username and hit enter'


  componentDidMount: ->

    channelNameInput = React.findDOMNode @refs.channelNameInput
    channelNameInput.focus()


  componentWillUnmount: ->

    CreateChannelFlux.actions.user.resetSelectedIndex()
    CreateChannelFlux.actions.user.unsetInputQuery()
    CreateChannelFlux.actions.channel.removeAllParticipants()


  getDataBindings: ->

    { getters } = CreateChannelFlux

    return {
      participants       : getters.createChannelParticipants
      query              : getters.createChannelParticipantsSearchQuery
      dropdownUsers      : getters.createChannelParticipantsInputUsers
      selectedItem       : getters.createChannelParticipantsSelectedItem
      selectedIndex      : getters.createChannelParticipantsSelectedIndex
      dropdownVisibility : getters.createChannelParticipantsDropdownVisibility
      selectedThread     : ActivityFlux.getters.selectedChannelThread
    }


  getDefaultPlaceholder: -> 'type a @username and hit enter'


  getParticipantsWrapperClassnames: -> classnames
    'delete-mode'                       : @state.deleteMode
    'CreateChannel-participantsWrapper' : yes


  getNameFieldClassnames: -> classnames
    'Reactivity-formfield' : yes
    'invalid'              : @state.invalidName


  getDropboxFieldClassnames: -> classnames
    'Reactivity-formfield' : yes
    'dropdown'             : yes
    'invalid'              : @state.invalidParticipants


  getModalProps: ->
    isOpen                : yes
    title                 : 'Create Channel'
    className             : 'CreateChannel-Modal'
    buttonConfirmTitle    : 'CREATE'
    onConfirm             : @bound 'createChannel'
    onClose               : @bound 'onClose'
    onAbort               : @bound 'onClose'


  setName: (event) ->

    value = event.target.value
    value = value.toLowerCase()
    @setState name: value
    @validateName(value)


  setPurpose: (event) ->

    @setState purpose: event.target.value


  onClose: (event) ->

    kd.utils.stopDOMEvent event

    return  unless @state.selectedThread
    return  if @_isCreating

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


  validateName: (value) ->

    pattern =  /^[a-z0-9]+$/i

    if value and pattern.test value
      @setState invalidName: no
      return yes
    else
      @setState invalidName: yes
      return no


  validateForm : ->

    if @validateName(@state.name)
      return yes
    return no


  createChannel: (event) ->

    kd.utils.stopDOMEvent event

    return  unless @validateForm()

    recipients = @prepareRecipients()
    options =
      type       : 'topic'
      name       : @state.name
      purpose    : @state.purpose
      recipients : recipients

    { createPublicChannel } = CreateChannelFlux.actions.channel

    @_isCreating = yes

    createPublicChannel(options)
      .then ({channel}) ->
        kd.singletons.router.handleRoute "/Channels/#{channel.name}"
      .catch =>
        @_isCreating = no


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


  render: ->

    <ActivityModal {...@getModalProps()}>
      <div className='CreateChannel-content'>
        <div className='CreateChannel-description'>
          <strong>This will create a new public channel that anyone on your team can join.</strong>
          <div>If you want this conversation to be private, you should create a new Private Group instead.</div>
        </div>
        <div className={@getNameFieldClassnames()}>
          <label className='Reactivity-label channelName'>Name</label>
          <input
            ref='channelNameInput'
            autoFocus=yes
            maxlength='20'
            className='Reactivity-input'
            value={@state.name}
            onChange={@bound 'setName'}
            onKeyDown={@bound 'onInputKeydown'}/>
          <span className='Reactivity-fieldMessage'>
            This is how this thread is going to appear on your sidebar.
          </span>
        </div>
        <div className='Reactivity-formfield'>
          <label className='Reactivity-label channelPurpose'>
            Purpose
            <span className='Reactivity-notRequired'> (optional)</span>
          </label>
          <input className='Reactivity-input'value={@state.purpose} maxlength='200' onChange={@bound 'setPurpose'} onKeyDown={@bound 'onInputKeydown'}/>
          <span className='Reactivity-fieldMessage'>
            Give your channel a purpose that describes what it will be used for.
          </span>
        </div>
        <div className={@getDropboxFieldClassnames()}>
          <label className='Reactivity-label inviteMembers'>Invite Members</label>
          {@renderAddParticipantInput()}
        </div>
      </div>
    </ActivityModal>


React.Component.include.call CreatePublicChannelModal, [KDReactorMixin]

