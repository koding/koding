kd           = require 'kd'
View         = require '../view'
expect       = require 'expect'
React        = require 'kd-react'
ReactDOM     = require 'react-dom'
immutable    = require 'immutable'
toImmutable  = require 'app/util/toImmutable'
TestUtils    = require 'react-addons-test-utils'
mock         = require '../../../../../mocks/mockingjay'
DropdownItem = require 'activity/components/channelparticipantsdropdownitem'


describe 'ChannelParticipantsDropdownView', ->

  {
    renderIntoDocument
    findRenderedDOMComponentWithClass
    scryRenderedDOMComponentsWithClass } = TestUtils


  beforeEach ->

    @props =
      closeAction          : kd.noop
      moveToPrevAction     : kd.noop
      moveToNextAction     : kd.noop
      onItemSelectedAction : kd.noop
      DropdownItem         : DropdownItem


  afterEach -> expect.restoreSpies()


  describe '::render', ->

    it 'should render channel participants dropdown with correct default props', ->

      view = renderIntoDocument(<View {...@props} />)

      expect(view.props.visible).toBeFalsy()
      expect(view.props.selectedIndex).toEqual 0
      expect(view.props.items instanceof immutable.List).toBeTruthy()


    it 'should render view and child nodes with correct classNames', ->

      view = renderIntoDocument(<View />)

      expect(findRenderedDOMComponentWithClass view, 'Dropbox-container').toExist()
      expect(findRenderedDOMComponentWithClass view, 'ChannelParticipantsDropdown').toExist()
      expect(findRenderedDOMComponentWithClass view, 'Dropdown-innerContainer').toExist()
      expect(findRenderedDOMComponentWithClass view, 'ChannelParticipantsDropdown-list').toExist()


    it 'should render channel participants dropdown with selected item by given selectedIndex', ->

      items        = toImmutable mock.getMockParticipants { size: 25 }
      view         = renderIntoDocument(<View {...@props} items={items} selectedIndex={null}/>)
      selectedItem = scryRenderedDOMComponentsWithClass view, 'DropboxItem-selected'

      expect(selectedItem.length).toEqual 0

      view         = renderIntoDocument(<View {...@props} items={items} selectedIndex={3}/>)
      selectedItem = scryRenderedDOMComponentsWithClass view, 'DropboxItem-selected'

      expect(selectedItem.length).toEqual 1


