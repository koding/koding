kd           = require 'kd'
expect       = require 'expect'
React        = require 'kd-react'
ReactDOM     = require 'react-dom'
immutable    = require 'immutable'
Container    = require '../container'
toImmutable  = require 'app/util/toImmutable'
TestUtils    = require 'react-addons-test-utils'
mock         = require '../../../../../mocks/mockingjay'
DropdownItem = require 'activity/components/channelparticipantsdropdownitem'

describe 'ChannelParticipantsDropdownContainer', ->

  { renderIntoDocument } = TestUtils


  beforeEach ->

    @props =
      closeAction          : kd.noop
      moveToPrevAction     : kd.noop
      moveToNextAction     : kd.noop
      onItemSelectedAction : kd.noop
      DropdownItem         : DropdownItem


  afterEach -> expect.restoreSpies()


  describe '::render', ->

    it 'should render channel participants dropdown container component with correct default props', ->

      container = renderIntoDocument(<Container {...@props} />)

      expect(container.props.visible).toBeFalsy()
      expect(container.props.selectedIndex).toEqual 0
      expect(container.props.onItemConfirmed).toExist()
      expect(container.props.selectedItem instanceof immutable.Map).toBeTruthy()
      expect(container.props.items instanceof immutable.List).toBeTruthy()


  describe '::formatSelectedValue', ->

    it 'should format selected participant nickname', ->

      selectedItem   = toImmutable mock.getMockAccount()
      nickname       = selectedItem.getIn(['profile','nickname'])
      container      = renderIntoDocument(<Container {...@props} selectedItem={selectedItem} />)
      formattedValue = container.formatSelectedValue()

      expect(formattedValue).toEqual "@#{nickname}"


  describe '::close', ->

    it 'should call passed onClose handler', ->

      onCloseSpy = expect.createSpy()
      container  = renderIntoDocument(<Container {...@props} closeAction={onCloseSpy} />)

      container.close()

      expect(onCloseSpy).toHaveBeenCalled()


  describe '::onItemSelected', ->

    it 'should call passed onItemSelectedAction handler with correct index', ->

      onItemSelectedSpy = expect.createSpy()
      container         = renderIntoDocument(<Container {...@props} onItemSelectedAction={onItemSelectedSpy} />)

      container.onItemSelected 3

      expect(onItemSelectedSpy).toHaveBeenCalledWith 3


  describe '::hasSingleItem', ->

    it 'should return no by given items prop', ->

      items     = toImmutable mock.getMockParticipants { size: 10 }
      container = renderIntoDocument(<Container {...@props} items={items} />)

      expect(container.hasSingleItem()).toBeFalsy()


    it 'should return yes by given items prop', ->

      items     = toImmutable mock.getMockParticipants { size: 1 }
      container = renderIntoDocument(<Container {...@props} items={items} />)

      expect(container.hasSingleItem()).toBeTruthy()


  describe '::isActive', ->

    it 'should return no by given visible and items props', ->

      items     = toImmutable mock.getMockParticipants { size: 10 }
      container = renderIntoDocument(<Container {...@props} items={items} visible={no} />)

      expect(container.isActive()).toBeFalsy()


    it 'should return no by given visible and items props', ->

      items     = immutable.List()
      container = renderIntoDocument(<Container {...@props} items={items} visible={yes} />)

      expect(container.isActive()).toBeFalsy()


    it 'should return yes by given visible and items props', ->

      items     = toImmutable mock.getMockParticipants { size: 10 }
      container = renderIntoDocument(<Container {...@props} items={items} visible={yes} />)

      expect(container.isActive()).toBeTruthy()


  describe '::confirmSelectedItem', ->

    it 'should call passed onItemConfirmed and closeAction handlers', ->

      onCloseSpy        = expect.createSpy()
      onItemSelectedSpy = expect.createSpy()
      selectedItem      = toImmutable mock.getMockAccount()

      newProps =
        selectedItem    : selectedItem
        closeAction     : onCloseSpy
        onItemConfirmed : onItemSelectedSpy

      container      = renderIntoDocument(<Container {...@props} {...newProps} />)
      formattedValue = container.formatSelectedValue()

      container.confirmSelectedItem()

      expect(onCloseSpy).toHaveBeenCalled()
      expect(onItemSelectedSpy).toHaveBeenCalledWith formattedValue


  describe '::moveToPrevPosition', ->

    it 'should call passed moveToPrevAction handler when key down up-arrow', ->

      moveToPrevSpy  = expect.createSpy()

      newProps =
        items            : toImmutable mock.getMockParticipants { size: 10 }
        visible          : yes
        moveToPrevAction : moveToPrevSpy

      container = renderIntoDocument(<Container {...@props} {...newProps}/>)

      container.moveToPrevPosition()

      expect(moveToPrevSpy).toHaveBeenCalled()


  describe '::moveToNextPosition', ->

    it 'should call passed moveToNextAction handler when key down down-arrow', ->

      moveToNextSpy  = expect.createSpy()

      newProps =
        items            : toImmutable mock.getMockParticipants { size: 10 }
        visible          : yes
        moveToNextAction : moveToNextSpy

      container = renderIntoDocument(<Container {...@props} {...newProps}/>)

      container.moveToNextPosition()

      expect(moveToNextSpy).toHaveBeenCalled()

