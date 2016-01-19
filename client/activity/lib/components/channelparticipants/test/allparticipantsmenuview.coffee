React     = require 'kd-react'
ReactDOM  = require 'react-dom'
expect    = require 'expect'
TestUtils = require 'react-addons-test-utils'
MenuView  = require '../allparticipantsmenuview'
mock      = require '../../../../../mocks/mockingjay'

describe 'ChannelAllParticipantsMenuView', ->

  { renderIntoDocument } = TestUtils


  beforeEach -> @participants = mock.getMockParticipants 25


  afterEach -> expect.restoreSpies()


  describe '::render', ->

    it 'should render all participants menu with correct amount of avatars', ->

      menuView = renderIntoDocument(<MenuView participants = { @participants }/>)

      node    = ReactDOM.findDOMNode(menuView)
      avatars = node.querySelectorAll('.ChannelParticipantAvatars-singleBox')
      expect(avatars.length).toEqual 25


    it 'should render correct title for all participants menu', ->

      menu  = renderIntoDocument(<MenuView participants = { @participants }/>)
      node  = ReactDOM.findDOMNode(menu.refs.AllParticipantsMenu)
      title = node.querySelector '.ChannelParticipantAvatars-allParticipantsMenuTitle'

      expect(title.textContent).toEqual 'Other participants'

