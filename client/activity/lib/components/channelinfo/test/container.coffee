kd              = require 'kd'
React           = require 'kd-react'
expect          = require 'expect'
ChannelInfo     = require '../index'
TestUtils       = require 'react-addons-test-utils'

{ createRenderer, renderIntoDocument } = TestUtils

describe 'ChannelInfoContainer', ->

  describe '::render', ->

    it 'should render ChannelInfo-Container and check its props', ->

      shallowRenderer = createRenderer()
      shallowRenderer.render(<ChannelInfo.Container />)

      container = shallowRenderer.getRenderOutput()

      expect(container.props.channel).toExist()
      expect(container.props.collabTooltipVisible).toBeFalsy()
      expect(container.props.integrationTooltipVisible).toBeFalsy()
      expect(container.props.onInviteClick).toBeA 'function'
      expect(container.props.onIntegrationClick).toBeA 'function'
      expect(container.props.onCollaborationClick).toBeA 'function'


  describe '::onCollaborationClick', ->

    it 'should show collaboration tooltip for 2 seconds', ->

      container = renderIntoDocument(<ChannelInfo.Container />)

      container.onCollaborationClick()

      expect(container.state.collabTooltipVisible).toBeTruthy()

      kd.utils.wait 2000, ->

        expect(container.state.collabTooltipVisible).toBeFalsy()


  describe '::onIntegrationClick', ->

    it 'should show integration tooltip for 2 seconds', ->

      container = renderIntoDocument(<ChannelInfo.Container />)

      container.onIntegrationClick()

      expect(container.state.integrationTooltipVisible).toBeTruthy()

      kd.utils.wait 2000, ->

        expect(container.state.integrationTooltipVisible).toBeFalsy()


  describe '::onInviteClick', ->

    it 'should call onInviteClick props', ->

      onInviteClick = expect.createSpy()
      container     = renderIntoDocument(<ChannelInfo.Container onInviteClick={onInviteClick}/>)

      container.onInviteClick()

      expect(onInviteClick).toHaveBeenCalled()

