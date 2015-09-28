kd                                = require 'kd'
Link                              = require 'app/components/common/link'
React                             = require 'kd-react'
Portal                            = require 'react-portal'
Avatar                            = require 'app/components/profile/avatar'
AppFlux                           = require 'app/flux'
TextArea                          = require 'react-autosize-textarea'
classnames                        = require 'classnames'
KeyboardKeys                      = require 'app/util/keyboardKeys'
ActivityFlux                      = require 'activity/flux'
ActivityModal                     = require 'app/components/activitymodal'
CreateChannelFlux                 = require 'activity/flux/createchannel'
KDReactorMixin                    = require 'app/flux/reactormixin'
DropboxInputMixin                 = require 'activity/components/dropbox/dropboxinputmixin'
ProfileLinkContainer              = require 'app/components/profile/profilelinkcontainer'
ChannelParticipantsDropdown       = require 'activity/components/channelparticipantsdropdown'
CreateChannelParticipantsDropdown = require 'activity/components/createchannelparticipantsdropdown'

module.exports = class CreatePrivateChannelModal extends React.Component

  @include [DropboxInputMixin]

  constructor: (props) ->

    super

    @state =
      name                : ''
      purpose             : ''
      query               : ''
      deleteMode          : no
      invalidName         : no
      invalidParticipants : no
      placeholder         : 'type a @username and hit enter'


  getDataBindings: ->

    { getters } = CreateChannelFlux

    return {
      participants        : getters.createChannelParticipants
      query               : getters.createChannelParticipantsSearchQuery
      dropdownUsers       : getters.createChannelParticipantsInputUsers
      selectedItem        : getters.createChannelParticipantsSelectedItem
      selectedIndex       : getters.createChannelParticipantsSelectedIndex
      dropdownVisibility  : getters.createChannelParticipantsDropdownVisibility
    }


  getDefaultPlaceholder: -> 'type a @username and hit enter'


  setName: (event) ->

    value = event.target.value
    value = value.toLowerCase()
    @setState name: value
    @validateName(value)


  setPurpose: (event) ->

    @setState purpose: event.target.value


  prepareRecipients: ->

    recipients = []

    @state.participants.map (participant) ->

      recipients.push participant.getIn ['profile', 'nickname']

    return recipients


  validateName: (value) ->

    pattern =  /^[a-z0-9]+$/i

    if value and pattern.test value
      @setState invalidName: no
      return yes
    else
      @setState invalidName: yes
      return no


  validateParticipants: () ->

    recipients = @prepareRecipients()

    if recipients.length
      @setState invalidParticipants: no
      return yes
    else
      @setState invalidParticipants: yes
      return no


  validateForm : ->

    isValidName         = @validateName(@state.name)
    isValidParticipants = @validateParticipants()

    if isValidName and isValidParticipants
      return yes
    return no


  createChannel: ->

    return  unless @validateForm()

    recipients = @prepareRecipients()
    options =
      body       : ''
      name       : @state.name
      purpose    : @state.purpose
      recipients : recipients

    { createPrivateChannel } = CreateChannelFlux.actions.channel

    createPrivateChannel(options).then ({channel}) =>

      @props.isOpen = no


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


  getParticipantsWrapperClassnames: -> classnames
    'delete-mode'                       : @state.deleteMode
    'CreateChannel-participantsWrapper' : yes


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


  getNameFieldClassnames: -> classnames
    'Reactivity-formfield' : yes
    'invalid'              : @state.invalidName


  getDropboxFieldClassnames: -> classnames
    'Reactivity-formfield' : yes
    'dropdown'             : yes
    'invalid'              : @state.invalidParticipants


  render: ->

    <ActivityModal {...@props} onConfirm={@bound 'createChannel'}>
      <div className='CreateChannel-content'>
        <div className='CreateChannel-description'>
          <strong>
            A private group is only visible to its members,
            and only members of a private group can read or search its contents.
          </strong>
          <div>{@props.extraInformation}</div>
        </div>
        <div className={@getDropboxFieldClassnames()}>
          <label className='Reactivity-label inviteMembers'>Invite Members</label>
          {@renderAddParticipantInput()}
        </div>
        <div className={@getNameFieldClassnames()}>
          <label className='Reactivity-label channelName'>Name</label>
          <input className='Reactivity-input' value={@state.name} maxlength='20' onChange={@bound 'setName'} onKeyDown={@bound 'onInputKeydown'}/>
          <span className='Reactivity-fieldMessage'>
            This is how this thread is going to appear on your sidebar.
          </span>
        </div>
        <div className='Reactivity-formfield'>
          <label className='Reactivity-label channelPurpose'>
            Purpose
            <span className='Reactivity-notRequired'> (optional)</span>
          </label>
          <input className='Reactivity-input' value={@state.purpose} maxlength='200' onChange={@bound 'setPurpose'} onKeyDown={@bound 'onInputKeydown'}/>
          <span className='Reactivity-fieldMessage'>
            Give your channel a purpose that describes what it will be used for.
          </span>
        </div>
      </div>
    </ActivityModal>


React.Component.include.call CreatePrivateChannelModal, [KDReactorMixin]

