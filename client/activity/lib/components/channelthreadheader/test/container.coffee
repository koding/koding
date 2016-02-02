kd           = require 'kd'
expect       = require 'expect'
React        = require 'kd-react'
ReactDOM     = require 'react-dom'
Container    = require '../container'
TestUtils    = require 'react-addons-test-utils'
toImmutable  = require 'app/util/toImmutable'
mock         = require '../../../../../mocks/mockingjay'
keyboardKeys = require 'app/constants/keyboardKeys'
ActivityFlux = require 'activity/flux'

{ renderIntoDocument } = TestUtils


describe 'ChannelThreadHeaderContainer', ->

  { ENTER, ESC } = keyboardKeys

  beforeEach ->

    channelId = 'koding-dummy-channel'

    @props =
      onInvitePeople             : kd.noop
      onLeaveChannel             : kd.noop
      onShowNotificationSettings : kd.noop
      thread                     : toImmutable mock.getMockThread({ channelId })


  afterEach -> expect.restoreSpies()


  describe '::render', ->

    it 'should render container with correct props', ->

      container = renderIntoDocument(<Container {...@props} />)

      expect(container.props.thread).toExist()
      expect(container.props.onInvitePeople).toBeA 'function'
      expect(container.props.onLeaveChannel).toBeA 'function'
      expect(container.props.onShowNotificationSettings).toBeA 'function'


  describe '::onKeyDown', ->

    it 'should set purpose state as _originalPurpose value', ->

      @props.thread = @props.thread.setIn ['channel', 'purpose'], 'edited purpose'
      @props.thread = @props.thread.setIn ['channel', '_originalPurpose'], 'original purpose'

      container = renderIntoDocument(<Container {...@props} />)
      container.setState { editingPurpose: yes }

      event = { key: 'Esc', keyCode: ESC, which: ESC }

      container.onKeyDown event

      purpose = container.state.thread.getIn ['channel', 'purpose']

      expect(purpose).toEqual 'original purpose'
      expect(container.props.editingPurpose).toBeFalsy()


    it 'should call updateChannel action with correct parameters and set editingPurpose state as no', ->

      { channel } = ActivityFlux.actions

      purpose          = 'purpose text'
      id               = @props.thread.getIn ['channel', 'id']
      updateChannelSpy = expect.spyOn(channel, 'updateChannel').andCallThrough()
      event            = { key: 'Enter', keyCode: ENTER, which: ENTER }
      @props.thread    = @props.thread.setIn ['channel', 'purpose'], purpose

      container = renderIntoDocument(<Container {...@props} />)

      container.onKeyDown event

      expect(updateChannelSpy).toHaveBeenCalledWith { id, purpose }
      expect(container.state.editingPurpose).toBeFalsy()


  describe '::onClose', ->

    it 'should set isModalOpen state value as no', ->

      container = renderIntoDocument(<Container {...@props} />)
      container.setState { isModalOpen: yes }

      container.onClose()

      expect(container.state.isModalOpen).toBeFalsy()


  describe '::onVideoStart', ->

    it 'should set isModalOpen state value as yes', ->

      @props.thread = null
      container = renderIntoDocument(<Container {...@props} />)
      container.setState { isModalOpen: no }

      container.onVideoStart()

      expect(container.state.isModalOpen).toBeTruthy()


  describe '::onUpdatePurpose', ->

    it 'should set editingPurpose state value as yes', ->

      container = renderIntoDocument(<Container {...@props} />)

      expect(container.state.editingPurpose).toBeFalsy()

      container.onUpdatePurpose()

      expect(container.state.editingPurpose).toBeTruthy()


  describe '::handlePurposeInputChange', ->

    it 'should update correct purpose value', ->

      container = renderIntoDocument(<Container {...@props} />)
      purpose   = @props.thread.getIn ['channel', 'purpose']

      expect(container.state.thread.getIn ['channel', '_originalPurpose']).toNotExist()

      container.handlePurposeInputChange 'edited purpose'

      { thread } = container.state

      expect(thread.getIn ['channel', 'purpose']).toEqual 'edited purpose'
      expect(thread.getIn ['channel', '_originalPurpose']).toEqual purpose


  describe '::getMenuItems', ->

    it 'should gets menu items array', ->

      container = renderIntoDocument(<Container {...@props} />)
      menuItems = container.getMenuItems()

      expect(menuItems).toBeA 'array'
      expect(menuItems.length).toEqual 4
      expect(menuItems[0].title).toEqual 'Invite people'
      expect(menuItems[1].title).toEqual 'Leave channel'
      expect(menuItems[2].title).toEqual 'Update purpose'
      expect(menuItems[3].title).toEqual 'Notification settings'
      expect(menuItems[0].onClick).toBeA 'function'
      expect(menuItems[1].onClick).toBeA 'function'
      expect(menuItems[2].onClick).toBeA 'function'
      expect(menuItems[3].onClick).toBeA 'function'

