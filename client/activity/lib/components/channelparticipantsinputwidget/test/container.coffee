React             = require 'kd-react'
expect            = require 'expect'
InputWidget       = require '../container'
immutable         = require 'immutable'
ActivityFlux      = require 'activity/flux'
TestUtils         = require 'react-addons-test-utils'
toImmutable       = require 'app/util/toImmutable'
mock              = require '../../../../../mocks/mockingjay'
{ channel, user } = ActivityFlux.actions

describe 'ChannelParticipantsInputWidgetContainer', ->

  { renderIntoDocument, isCompositeComponent } = TestUtils

  beforeEach ->

    @props =
      selectedIndex         : 1
      addNewParticipantMode : no
      visible               : yes
      selectedItem          : toImmutable mock.getMockAccount()
      items                 : immutable.List()
      query                 : 'koding-dummy-query'
      value                 : 'koding-dummy-query'
      channelId             : 'koding-dummy-channel'
      placeholder           : 'koding-dummy-placeholder'


  afterEach  -> expect.restoreSpies()


  describe '::render', ->

    it 'should render ChannelParticipantsInputWidgetContainer with correct props and pass required handlers to view', ->

      container = renderIntoDocument(<InputWidget {...@props}/>)

      expect(container.props.visible).toBeTruthy()
      expect(container.props.items).toBeA(immutable.List)
      expect(container.props.addNewParticipantMode).toBeFalsy()
      expect(isCompositeComponent(container.refs.view)).toBeTruthy()
      expect(container.props.selectedIndex).toEqual 1
      expect(container.props.value).toEqual 'koding-dummy-query'
      expect(container.props.query).toEqual 'koding-dummy-query'
      expect(container.props.placeholder).toEqual 'koding-dummy-placeholder'
      expect(container.refs.view.props.onChange).toBeA 'function'
      expect(container.refs.view.props.onKeyDown).toBeA 'function'
      expect(container.refs.view.props.onItemConfirmed).toBeA 'function'


  describe '::onDropdownItemConfirmed', ->

    it 'should call addParticipants action and set state value empty when dropdown item confirmed', ->

      addParticipantsSpy = expect.spyOn channel, 'addParticipants'

      container = renderIntoDocument(<InputWidget {...@props} />)
      container.onDropdownItemConfirmed()

      { selectedItem, channelId } = @props

      userIds    = [ selectedItem.get '_id' ]
      accountIds = [ selectedItem.get 'socialApiId' ]

      expect(addParticipantsSpy).toHaveBeenCalledWith channelId, accountIds, userIds
      expect(container.state.value).toEqual ''


  describe '::onChange', ->

    it 'should call correct actions with given parameters and set state with given target value', ->

      querySpy      = expect.spyOn user, 'setChannelParticipantsInputQuery'
      visibilitySpy = expect.spyOn channel, 'setChannelParticipantsDropdownVisibility'

      event =
        target:
          value: 'koding-dummy-query'

      container = renderIntoDocument(<InputWidget {...@props} />)
      container.onChange(event)

      expect(container.state.value).toEqual 'koding-dummy-query'
      expect(querySpy).toHaveBeenCalledWith 'koding-dummy-query'
      expect(visibilitySpy).toHaveBeenCalledWith yes


  describe '::getDropdown', ->

    it 'should get the dropdown component', ->

      container = renderIntoDocument(<InputWidget {...@props} />)
      dropdown  = container.getDropdown()

      expect(isCompositeComponent dropdown).toBeTruthy()


