React              = require 'kd-react'
ReactDOM           = require 'react-dom'
expect             = require 'expect'
Modal              = require '../index'
ModalView          = require '../view'
TestUtils          = require 'react-addons-test-utils'
ActivityFlux       = require 'activity/flux'
Tabs               = require 'activity/constants/sidebarpublicchannelstabs'
expectCorrectRoute = require 'activity/test/helpers/expectCorrectRoute'

describe 'BrowsePublicChannelsModalContainer', ->

  { createRenderer, renderIntoDocument } = TestUtils
  { channel } = ActivityFlux.actions

  afterEach -> expect.restoreSpies()


  describe '::render', ->

    it 'renders BrowsePublicChannelsModal with PublicChannelListModal and ChannelList-Modal classNames', ->

      shallowRenderer = createRenderer()
      shallowRenderer.render(<Modal />)

      modal = shallowRenderer.getRenderOutput()

      expect(modal.props.isOpen).toBeTruthy()
      expect(modal.props.className).toContain 'PublicChannelListModal'
      expect(modal.props.className).toContain 'ChannelList-Modal'


    it 'renders child component of modal with ChannelListWrapper className and 3 childs', ->

      shallowRenderer = createRenderer()
      shallowRenderer.render(<Modal />)

      modal = shallowRenderer.getRenderOutput()
      { children } = modal.props

      expect(children.props.className).toEqual 'ChannelListWrapper'
      expect(children.props.children.length).toEqual 3


    it 'renders modal child component DOM node with Modal-container className', ->

      modal = renderIntoDocument(<Modal isOpen={no}/>)
      node  = ReactDOM.findDOMNode modal

      expect(node.className).toEqual 'Modal-container'


  describe '::onItemClick', ->

    it 'should update skipCloseHandling flag to true', ->

      modal = renderIntoDocument(<Modal.Container isOpen={no}/>)

      expect(modal.skipCloseHandling).toBeFalsy()
      expect(modal.onItemClick()).toBeTruthy()
      expect(modal.skipCloseHandling).toBeTruthy()


  describe '::onOtherChannelsClick', ->

    it 'should call channel actions loadChannels and setSidebarPublicChannelsTab methods', ->

      modal           = renderIntoDocument(<Modal.Container isOpen={no}/>)
      channelsTabSpy  = expect.spyOn channel, 'setSidebarPublicChannelsTab'
      loadChannelsSpy = expect.spyOn channel, 'loadChannels'

      modal.onOtherChannelsClick()

      expect(loadChannelsSpy).toHaveBeenCalled()
      expect(channelsTabSpy).toHaveBeenCalledWith Tabs.OtherChannels


  describe '::onYourChannelsClick', ->

    it 'should call channel actions loadFollowedPublicChannels and setSidebarPublicChannelsTab methods', ->

      modal                   = renderIntoDocument(<Modal.Container isOpen={no}/>)
      channelsTabSpy          = expect.spyOn channel, 'setSidebarPublicChannelsTab'
      loadFollowedChannelsSpy = expect.spyOn channel, 'loadFollowedPublicChannels'

      modal.onYourChannelsClick()

      expect(loadFollowedChannelsSpy).toHaveBeenCalled()
      expect(channelsTabSpy).toHaveBeenCalledWith Tabs.YourChannels


  describe '::onSearchInputChange', ->

    it 'should call channel actions loadChannelsByQuery and setSidebarPublicChannelsQuery methods with given value', ->

      modal                  = renderIntoDocument(<Modal.Container isOpen={no}/>)
      loadChannelsByQuerySpy = expect.spyOn channel, 'loadChannelsByQuery'
      publicChannelsQuerySpy = expect.spyOn channel, 'setSidebarPublicChannelsQuery'

      dummyValue = 'input-dummy-value'

      mockEvent =
        target:
          value: ''

      modal.onSearchInputChange mockEvent

      expect(loadChannelsByQuerySpy).toNotHaveBeenCalled()
      expect(publicChannelsQuerySpy).toHaveBeenCalledWith ''

      mockEvent.target.value = dummyValue

      modal.onSearchInputChange mockEvent

      expect(loadChannelsByQuerySpy).toHaveBeenCalledWith dummyValue
      expect(publicChannelsQuerySpy).toHaveBeenCalledWith dummyValue


  describe '::onTabChange', ->

    it 'should call modal-container onYourChannelsClick method', ->

      modal = renderIntoDocument(<Modal.Container isOpen={no}/>)
      spy   = expect.spyOn modal, 'onYourChannelsClick'

      modal.onTabChange Tabs.YourChannels

      expect(spy).toHaveBeenCalled()


    it 'should call modal-container onOtherChannelsClick method', ->

      modal = renderIntoDocument(<Modal.Container isOpen={no}/>)
      spy   = expect.spyOn modal, 'onOtherChannelsClick'

      modal.onTabChange Tabs.OtherChannels

      expect(spy).toHaveBeenCalled()


  describe '::onThresholdReached', ->

    it 'should call channel actions loadChannelsByQuery method with given options', ->

      modal   = renderIntoDocument(<Modal.Container isOpen={no}/>)
      spy     = expect.spyOn channel, 'loadChannelsByQuery'
      query   = 'dummy-query'
      options = { key : 'dummy-value' }

      modal.setState { query }

      modal.onThresholdReached options

      expect(spy).toHaveBeenCalledWith 'dummy-query', options


    it 'should call channel actions loadFollowedPublicChannels method with given options', ->

      modal   = renderIntoDocument(<Modal.Container isOpen={no}/>)
      spy     = expect.spyOn channel, 'loadFollowedPublicChannels'
      query   = 'dummy-query'
      options = { key : 'dummy-value' }

      modal.setState tab: Tabs.YourChannels

      modal.onThresholdReached options

      expect(spy).toHaveBeenCalledWith options


    it 'should call channel actions loadChannels method with given options', ->

      modal   = renderIntoDocument(<Modal.Container isOpen={no}/>)
      spy     = expect.spyOn channel, 'loadChannels'
      options = { key : 'dummy-value' }

      modal.setState tab: Tabs.OtherChannels

      modal.onThresholdReached options

      expect(spy).toHaveBeenCalledWith options


  describe '::onClose', ->

    it 'should call router.handleRoute method with public route parameter', ->

      expectCorrectRoute Modal, 'koding-dummy-channel', 'topic', "/Channels/koding-dummy-channel"


    it 'should call router.handleRoute method with private route parameter', ->

      expectCorrectRoute Modal, 'koding-12345', 'privatemessage', "/Messages/koding-12345"

