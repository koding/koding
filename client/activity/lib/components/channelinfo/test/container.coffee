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
      expect(container.props.onInviteOthers).toBeA 'function'
      expect(container.props.onIntegrationHelp).toBeA 'function'
      expect(container.props.onCollaborationHelp).toBeA 'function'


  describe '::onCollaborationHelp', ->

    it 'should set collabTooltipVisible state yes first, after 2000 millisecond set to false', ->

      container = renderIntoDocument(<ChannelInfo.Container />)

      container.onCollaborationHelp()

      expect(container.state.collabTooltipVisible).toBeTruthy()

      kd.utils.wait 2000, ->

        expect(container.state.collabTooltipVisible).toBeFalsy()


  describe '::onIntegrationHelp', ->

    it 'should set integrationTooltipVisible state yes first, after 2000 millisecond set to false', ->

      container = renderIntoDocument(<ChannelInfo.Container />)

      container.onIntegrationHelp()

      expect(container.state.integrationTooltipVisible).toBeTruthy()

      kd.utils.wait 2000, ->

        expect(container.state.integrationTooltipVisible).toBeFalsy()


  describe '::onInviteOthers', ->

    it 'should call onInviteOthers props', ->

      onInviteOthers  = expect.createSpy()
      container       = renderIntoDocument(<ChannelInfo.Container onInviteOthers={onInviteOthers}/>)

      container.onInviteOthers()

      expect(onInviteOthers).toHaveBeenCalled()

      expect.restoreSpies()

