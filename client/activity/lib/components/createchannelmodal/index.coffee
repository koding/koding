kd                                = require 'kd'
Link                              = require 'app/components/common/link'
React                             = require 'kd-react'
Portal                            = require 'react-portal'
Avatar                            = require 'app/components/profile/avatar'
AppFlux                           = require 'app/flux'
TextArea                          = require 'react-autosize-textarea'
classnames                        = require 'classnames'
ActivityFlux                      = require 'activity/flux'
ActivityModal                     = require 'app/components/activitymodal'
CreateChannelFlux                 = require 'activity/flux/createchannel'
KDReactorMixin                    = require 'app/flux/reactormixin'
DropboxInputMixin                 = require 'activity/components/dropbox/dropboxinputmixin'
ProfileLinkContainer              = require 'app/components/profile/profilelinkcontainer'
ChannelParticipantsDropdown       = require 'activity/components/channelparticipantsdropdown'
CreateChannelParticipantsDropdown = require 'activity/components/createchannelparticipantsdropdown'

module.exports = class CreateChannelModal extends React.Component

  @include [DropboxInputMixin]

  constructor: (props) ->

    super

    @state =
      name        : ''
      purpose     : ''
      query       : ''
      placeholder : 'type a @username and hit enter'
      deleteMode  : no


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


  createChannel: ->

    console.log 'create channel'


  createPrivateGroup: (event) ->

    kd.utils.stopDOMEvent event
    console.log 'create channel'


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


  render: ->

    <ActivityModal {...@props} onConfirm={@bound 'createChannel'}>
      <div className='CreateChannel-content'>
        <div className='CreateChannel-description'>
          <strong>This will create a new public channel that anyone on your team can join. </strong>
          <div>
            If you need this conversation to be private, you should
            <Link className='CreateChannel-createPrivateGroup' onClick={@bound 'createPrivateGroup'}> create a new Private Group instead.</Link>
          </div>
        </div>
        <div className='Reactivity-formfield'>
          <label className='Reactivity-label channelName'>Name</label>
          <input className='Reactivity-input'/>
          <span className='Reactivity-fieldMessage'>
            Names must be 21 characters or less, lower case and cannot contain spaces or periods.
          </span>
        </div>
        <div className='Reactivity-formfield'>
          <label className='Reactivity-label channelPurpose'>
            Purpose
            <span className='Reactivity-notRequired'>(optional)</span>
          </label>
          <TextArea className='Reactivity-textarea'/>
          <span className='Reactivity-fieldMessage'>
            Give your channel a purpose that describes what it will be used for.
          </span>
        </div>
        <div className='Reactivity-formfield dropdown'>
          <label className='Reactivity-label inviteMembers'>Invite Members</label>
          {@renderAddParticipantInput()}
        </div>
      </div>
    </ActivityModal>


React.Component.include.call CreateChannelModal, [KDReactorMixin]

