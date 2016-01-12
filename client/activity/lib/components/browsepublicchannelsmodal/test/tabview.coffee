React     = require 'kd-react'
ReactDOM  = require 'react-dom'
expect    = require 'expect'
TabView   = require '../tabview'
TestUtils = require 'react-addons-test-utils'
Tabs      = require 'activity/constants/sidebarpublicchannelstabs'

describe 'BrowsePublicChannelsModalTabView', ->

  { Simulate, createRenderer, renderIntoDocument } = TestUtils


  describe '::render', ->

    it 'checks rendered tabView and its children props', ->

      shallowRenderer = createRenderer()
      shallowRenderer.render(<TabView />)

      tabView = shallowRenderer.getRenderOutput()
      { children } = tabView.props

      expect(tabView.type).toEqual 'div'
      expect(tabView.props.className).toEqual 'ChannelList-tabs'
      expect(children.length).toEqual 3
      expect(children[0].ref).toEqual 'yourChannels'
      expect(children[1].ref).toEqual 'otherChannels'
      expect(children[0].props.children).toEqual 'Your Channels'
      expect(children[1].props.children).toEqual 'Other Channels'
      expect(children[0].props.className).toEqual 'ChannelList-tab'
      expect(children[1].props.className).toEqual 'ChannelList-tab'
      expect(children[2].props.className).toEqual 'clearfix'


  describe '::onClick', ->

    it 'should call onChange method of tabview with given parameter', ->

      onChange      = expect.createSpy()
      tabView       = renderIntoDocument(<TabView onChange={onChange}/>)
      yourChannels  = tabView.refs.yourChannels
      otherChannels = tabView.refs.otherChannels

      TestUtils.Simulate.click yourChannels

      expect(onChange).toHaveBeenCalledWith(Tabs.YourChannels)

      TestUtils.Simulate.click otherChannels

      expect(onChange).toHaveBeenCalledWith(Tabs.OtherChannels)

      expect.restoreSpies()