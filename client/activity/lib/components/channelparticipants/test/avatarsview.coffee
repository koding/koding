React       = require 'kd-react'
ReactDOM    = require 'react-dom'
expect      = require 'expect'
AvatarsView = require '../avatarsview'
TestUtils   = require 'react-addons-test-utils'
mock        = require '../../../../../mocks/mockingjay'

describe 'ChannelParticipantsAvatarsView', ->

  { renderIntoDocument } = TestUtils


  beforeEach ->

    @participants = mock.getMockParticipants 25


  afterEach -> expect.restoreSpies()


  describe '::render', ->

    it 'should render AvatarsView with correct props', ->

      avatarsView  = renderIntoDocument(<AvatarsView
        className           = 'koding-dummy-class'
        participants        = { @participants }
        isNicknameVisible   = { no }
        shouldTooltipRender = { yes }/>)

      expect(avatarsView.props.participants).toExist()
      expect(avatarsView.props.isNicknameVisible).toBeFalsy()
      expect(avatarsView.props.shouldTooltipRender).toBeTruthy()
      expect(avatarsView.props.className).toEqual 'koding-dummy-class'


    it 'should render correct amount of participant avatars', ->

      avatarsView  = renderIntoDocument(<AvatarsView participants={@participants}/>)
      node         = ReactDOM.findDOMNode(avatarsView)
      avatars      = node.querySelectorAll('.ChannelParticipantAvatars-singleBox')

      expect(avatars.length).toEqual 25

