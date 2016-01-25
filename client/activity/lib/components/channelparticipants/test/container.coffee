React       = require 'kd-react'
ReactDOM    = require 'react-dom'
expect      = require 'expect'
Container   = require '../container'
toImmutable = require 'app/util/toImmutable'
TestUtils   = require 'react-addons-test-utils'
mock        = require '../../../../../mocks/mockingjay'

describe 'ChannelParticipantsContainer', ->

  { renderIntoDocument, isCompositeComponent } = TestUtils


  beforeEach ->

    @participants = mock.getMockParticipants { size: 25 }
    channelId     = 'dummy-channel-id'
    @mockThread   = toImmutable mock.getMockThread { channelId }

    @container = renderIntoDocument(<Container
      channelThread = { @mockThread }
      participants  = { @participants }/>)


  afterEach -> expect.restoreSpies()


  describe '::render', ->

    it 'should render avatars container with correct props and state', ->

      expect(isCompositeComponent(@container.refs.view)).toBeTruthy()
      expect(@container.props.channelThread).toExist()
      expect(@container.props.participants).toExist()
      expect(@container.state.dropdownVisibility).toBeFalsy()
      expect(@container.state.showAllParticipants).toBeFalsy()
      expect(@container.state.addNewParticipantMode).toBeFalsy()


    it 'should render participant avatars wrapper and participant input wrapper elements', ->

      node    = ReactDOM.findDOMNode(@container)
      input   = node.querySelector '.ChannelParticipantInput'
      avatars = node.querySelector '.ChannelParticipantAvatars'

      expect(input).toExist()
      expect(avatars).toExist()


  describe '::onNewParticipantButtonClick', ->

    it 'should toggle addNewParticipantMode state', ->

      oldState = @container.state.addNewParticipantMode

      @container.onNewParticipantButtonClick()

      expect(@container.state.addNewParticipantMode).toNotEqual oldState

      @container.onNewParticipantButtonClick()

      expect(@container.state.addNewParticipantMode).toEqual oldState


  describe '::onShowMoreParticipantsButtonClick', ->

    it 'should toggle showAllParticipants state', ->

      event    = document.createEvent('Event')
      oldState = @container.state.showAllParticipants

      @container.onShowMoreParticipantsButtonClick(event)

      expect(@container.state.showAllParticipants).toNotEqual oldState

      @container.onShowMoreParticipantsButtonClick(event)

      expect(@container.state.showAllParticipants).toEqual oldState


  describe '::handleOutsideMouseClick', ->

    it 'should set showAllParticipants state as false', ->

      event        = document.createEvent('Event')
      event.target = document.body

      @container.setState { showAllParticipants : yes }

      expect(@container.state.showAllParticipants).toBeTruthy()

      @container.handleOutsideMouseClick(event)

      expect(@container.state.showAllParticipants).toBeFalsy()







