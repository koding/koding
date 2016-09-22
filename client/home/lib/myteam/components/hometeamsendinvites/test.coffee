kd                 = require 'kd'
React              = require 'app/react'
ReactDOM           = require 'react-dom'
expect             = require 'expect'
TeamSendInvites    = require './view'
TestUtils          = require 'react-addons-test-utils'
toImmutable        = require 'app/util/toImmutable'
Encoder            = require 'htmlencode'
mock               = require '../../../../../mocks/mockingjay'
immutable          = require 'immutable'


describe 'HomeTeamSendInvites', ->

  { createRenderer,
  renderIntoDocument,
  findRenderedDOMComponentWithClass,
  scryRenderedDOMComponentsWithClass } = TestUtils

  describe '::render', ->

    it 'should render invite labels', ->

      teamSendInvites = renderIntoDocument <TeamSendInvites />
      inviteLabels = findRenderedDOMComponentWithClass teamSendInvites, 'invite-labels'
      actualText = 'EmailFirst NameLast NameAdmin'

      expect(inviteLabels.textContent).toEqual actualText


    it 'should render correct invite inputs', ->

      inviteInputs = mock.getTeamSendInvites()
      inviteInputs = immutable.fromJS inviteInputs

      teamSendInvites = renderIntoDocument <TeamSendInvites inviteInputs={inviteInputs} onInputChange={kd.noop}/>

      inputs = scryRenderedDOMComponentsWithClass teamSendInvites, 'kdview invite-inputs'

      expect(inputs.length).toEqual 3


    it 'should render correct invite inputs and admin checks', ->

      inviteInputs = mock.getTeamSendInvites()
      input = {'firstname':'', 'lastname':'', 'email':'', 'role':'admin' }
      inviteInputs[3] = input
      inviteInputs = immutable.fromJS inviteInputs

      teamSendInvites = renderIntoDocument <TeamSendInvites inviteInputs={inviteInputs} onInputChange={kd.noop}/>
      inputs = scryRenderedDOMComponentsWithClass teamSendInvites, 'kdview invite-inputs'

      expect(inputs.length).toEqual 4

      inputs = inputs.filter (input) -> input.innerHTML.indexOf("checked=") > 0

      expect(inputs.length).toEqual 2


    it 'should render correct buttons', ->

      teamSendInvites = renderIntoDocument <TeamSendInvites />

      buttons = scryRenderedDOMComponentsWithClass teamSendInvites,'custom-link-view HomeAppView--button'
      buttons = buttons.map (button) -> button.innerText
      buttons = buttons.sort()

      actualButtons = ['SEND INVITES', 'UPLOAD CSV']

      expect(buttons).toEqual actualButtons
