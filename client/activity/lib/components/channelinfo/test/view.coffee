kd              = require 'kd'
React           = require 'kd-react'
ReactDOM        = require 'react-dom'
expect          = require 'expect'
ChannelInfoView = require '../view'
mock            = require '../../../../../mocks/mockingjay'
TestUtils       = require 'react-addons-test-utils'
toImmutable     = require 'app/util/toImmutable'
whoami          = require 'app/util/whoami'

{ Simulate, createRenderer, renderIntoDocument } = TestUtils


describe 'ChannelInfoView', ->

  afterEach -> expect.restoreSpies()

  describe '::render', ->

    it 'should have correct children for default', ->

      shallowRenderer = createRenderer()
      shallowRenderer.render(<ChannelInfoView />)

      channelInfoView = shallowRenderer.getRenderOutput()

      expect(channelInfoView.type).toEqual 'div'
      expect(channelInfoView.props.className).toEqual 'ChannelInfoContainer'
      expect(channelInfoView.props.children.length).toEqual 3


    it 'should show correct name for bot channel', ->

      options = { typeConstant : 'bot' }
      channel = toImmutable mock.getMockChannel options

      channelInfoView   = renderIntoDocument(<ChannelInfoView channel={channel}/>)
      infoContainerName = ReactDOM.findDOMNode(channelInfoView).querySelector '.ChannelInfoContainer-name'

      expect(infoContainerName.textContent).toEqual 'Koding Bot'


    it 'should show correct name for public channels', ->

      options =
        typeConstant : 'topic'
        channelName  : 'koding-dummy-channel'

      channel = toImmutable mock.getMockChannel options

      channelInfoView   = renderIntoDocument(<ChannelInfoView channel={channel}/>)
      infoContainerName = ReactDOM.findDOMNode(channelInfoView).querySelector '.ChannelInfoContainer-name'

      expect(infoContainerName.textContent).toEqual '#koding-dummy-channel'


    it 'should show a description instead of a name for a private channels', ->

      options = { typeConstant : 'privatemessage' }
      channel = toImmutable mock.getMockChannel options

      channelInfoView   = renderIntoDocument(<ChannelInfoView channel={channel}/>)
      infoContainerName = ReactDOM.findDOMNode(channelInfoView).querySelector '.ChannelInfoContainer-name'

      expect(infoContainerName.textContent).toEqual 'This is a private conversation.'


    it 'should show special label when channel is created by logged in user', ->

      accountOldId = whoami().id
      createdAt    = new Date()
      options      = { typeConstant : 'topic', accountOldId, createdAt }
      channel      = toImmutable mock.getMockChannel options

      channelInfoView = renderIntoDocument(<ChannelInfoView channel={channel}/>)
      profileLink     = ReactDOM.findDOMNode(channelInfoView).querySelector '.ChannelInfoContainer-profileLink'

      # first render 'a koding user' then it updates to 'you', so we wait a second
      # then check the textContent
      kd.utils.wait 1000, ->

        expect(profileLink.textContent).toEqual ', created by you today.'


  describe '::onClick', ->


    it 'should call onIntegrationHelp when click AddIntegrationLink element', ->

      onIntegrationHelp  = expect.createSpy()
      channelInfoView    = renderIntoDocument(<ChannelInfoView onIntegrationHelp={onIntegrationHelp}/>)
      addIntegrationLink = ReactDOM.findDOMNode(channelInfoView).querySelector '.AddIntegrationLink'

      Simulate.click addIntegrationLink

      expect(onIntegrationHelp).toHaveBeenCalled()


    it 'should call passed handler on collaboration link click', ->

      onCollaborationHelp    = expect.createSpy()
      channelInfoView        = renderIntoDocument(<ChannelInfoView onCollaborationHelp={onCollaborationHelp}/>)
      startCollaborationLink = ReactDOM.findDOMNode(channelInfoView).querySelector '.StartCollaborationLink'

      Simulate.click startCollaborationLink

      expect(onCollaborationHelp).toHaveBeenCalled()


    it 'should call passed handler on invite others link click', ->

      onInviteOthers   = expect.createSpy()
      channelInfoView  = renderIntoDocument(<ChannelInfoView onInviteOthers={onInviteOthers}/>)
      inviteOthersLink = ReactDOM.findDOMNode(channelInfoView).querySelector '.InviteOthersLink'

      Simulate.click inviteOthersLink

      expect(onInviteOthers).toHaveBeenCalled()

