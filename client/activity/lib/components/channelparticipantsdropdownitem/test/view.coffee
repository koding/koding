expect      = require 'expect'
View        = require '../view'
React       = require 'kd-react'
ReactDOM    = require 'react-dom'
immutable   = require 'immutable'
toImmutable = require 'app/util/toImmutable'
TestUtils   = require 'react-addons-test-utils'
mock        = require '../../../../../mocks/mockingjay'

describe 'ChannelParticipantsDropdownItemView', ->

  { renderIntoDocument } = TestUtils


  describe '::render', ->

    it 'should render view with correct props', ->

      account = toImmutable mock.getMockAccount()
      view    = renderIntoDocument(<View item={account}/>)

      expect(view.props.index).toBeA 'number'
      expect(view.props.index).toEqual 0
      expect(view.props.isSelected).toBeA 'boolean'
      expect(view.props.isSelected).toEqual no
      expect(view.props.item).toBeAn immutable.Map


    it 'should render dom node with correct classnames', ->

      account = toImmutable mock.getMockAccount()
      view    = renderIntoDocument(<View item={account}/>)
      node    = ReactDOM.findDOMNode(view)

      expect(node.className).toContain 'DropboxItem'
      expect(node.className).toContain 'ChannelParticipantsDropdownItem'


    it 'should render view with correct nickname', ->

      account  = toImmutable mock.getMockAccount()
      view     = renderIntoDocument(<View item={account}/>)
      node     = ReactDOM.findDOMNode(view)
      nickname = node.querySelector '.ChannelParticipantsDropdownItem-nickname'

      expect(nickname.textContent).toEqual account.getIn ['profile', 'nickname']




