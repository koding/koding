React        = require 'kd-react'
ReactDOM     = require 'react-dom'
expect       = require 'expect'
ChannelLabel = require '../index'
toImmutable  = require 'app/util/toImmutable'
TestUtils    = require 'react-addons-test-utils'
mock         = require '../../../../../mocks/mockingjay'


describe 'ChannelLabelView', ->

  { renderIntoDocument } = TestUtils

  afterEach -> expect.restoreSpies()

  describe '::render', ->

    it 'should show correct channel name for public channels', ->

      typeConstant   = 'topic'
      channelName    = 'koding-dummy-channel'
      channelOptions = { channelName, typeConstant }
      mockChannel    = toImmutable mock.getMockChannel channelOptions

      channelLabel   = renderIntoDocument(<ChannelLabel channel={mockChannel} />)

      node = ReactDOM.findDOMNode(channelLabel)

      expect(node.textContent).toEqual '#koding-dummy-channel'


    it 'should show correct channel name for koding user', ->

      typeConstant   = 'privatemessage'
      channelName    = ''
      channelOptions = { channelName, typeConstant }
      mockChannel    = toImmutable mock.getMockChannel channelOptions

      channelLabel   = renderIntoDocument(<ChannelLabel channel={mockChannel} />)

      node = ReactDOM.findDOMNode(channelLabel)

      expect(node.textContent).toEqual 'a koding user'


    it 'should show correct channel name for private channels', ->

      account        = mock.getMockAccount()
      participants   = [ account ]
      typeConstant   = 'privatemessage'
      channelName    = ''
      channelOptions = { channelName, typeConstant, participantsPreview: participants }
      mockChannel    = toImmutable mock.getMockChannel channelOptions

      channelLabel   = renderIntoDocument(<ChannelLabel channel={mockChannel} />)

      node = ReactDOM.findDOMNode(channelLabel)

      expect(node.textContent).toEqual "#{account.profile.firstName} #{account.profile.lastName}"

