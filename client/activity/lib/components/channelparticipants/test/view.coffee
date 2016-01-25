React       = require 'kd-react'
ReactDOM    = require 'react-dom'
expect      = require 'expect'
View        = require '../view'
immutable   = require 'immutable'
TestUtils   = require 'react-addons-test-utils'
toImmutable = require 'app/util/toImmutable'
mock        = require '../../../../../mocks/mockingjay'

describe 'ChannelParticipantsView', ->

  { Simulate, renderIntoDocument, isCompositeComponent } = TestUtils


  beforeEach -> @participants = mock.getMockParticipants { size: 25 }


  afterEach  -> expect.restoreSpies()


  describe '::render', ->

    it 'should render ChannelParticipantsView with correct props', ->

      view = renderIntoDocument(<View />)

      expect(view.props.value).toBeA 'string'
      expect(view.props.query).toBeA 'string'

      expect(isCompositeComponent(view.refs.InputWidget)).toBeTruthy()
      expect(view.props.visible).toBeFalsy()
      expect(view.props.isParticipant).toBeFalsy()
      expect(view.props.showAllParticipants).toBeFalsy()
      expect(view.props.addNewParticipantMode).toBeFalsy()
      expect(view.props.items).toBeA(immutable.List)
      expect(view.props.participants).toBeA(immutable.Map)


    it 'should render correct text content for show more count part', ->

      view          = renderIntoDocument(<View participants={@participants}/>)
      moreCountNode = ReactDOM.findDOMNode(view).querySelector('.ChannelParticipantAvatars-moreCount')

      expect(moreCountNode.textContent).toEqual '+7'


    it 'should render correct amount of avatar for all participants menu list', ->

      view      = renderIntoDocument(<View participants={@participants} showAllParticipants={yes}/>)
      menu      = ReactDOM.findDOMNode(view.refs.AllParticipantsMenu)
      container = menu.querySelector '.ChannelParticipantAvatars-allParticipantsList'
      avatars   = container.querySelectorAll '.ChannelParticipantAvatars-singleBox'

      expect(avatars.length).toEqual 7


  describe '::onNewParticipantButtonClick', ->

    it 'should call passed handler on add new participant button click', ->

      addNewParticipantSpy  = expect.createSpy()

      view = renderIntoDocument(<View onNewParticipantButtonClick={addNewParticipantSpy} />)
      node = ReactDOM.findDOMNode(view)
      link = node.querySelector '.ChannelParticipantAvatars-newParticipantBox'

      Simulate.click link

      expect(addNewParticipantSpy).toHaveBeenCalled()


  describe '::onShowMoreParticipantsButtonClick', ->

    it 'should call passed handler on show more participants button click', ->

      showMoreSpy  = expect.createSpy()

      view = renderIntoDocument(<View participants={@participants} onShowMoreParticipantsButtonClick={showMoreSpy} />)
      node = ReactDOM.findDOMNode(view)
      link = node.querySelector '.ChannelParticipantAvatars-moreCount'

      Simulate.click link

      expect(showMoreSpy).toHaveBeenCalled()


  describe '::getPreviewCount', ->

    it 'should calculate correct preview count for less than max_preview_count', ->

      participants = mock.getMockParticipants { size: 12 }

      view = renderIntoDocument(<View participants={participants}/>)

      expect(view.getPreviewCount()).toEqual 12


    it 'should calculate correct preview count for max_preview_count', ->

      participants = mock.getMockParticipants { size: 19 }

      view = renderIntoDocument(<View participants={participants}/>)

      expect(view.getPreviewCount()).toEqual 19


    it 'should calculate correct preview count for greater than max_preview_count', ->

      view = renderIntoDocument(<View participants={@participants}/>)

      expect(view.getPreviewCount()).toEqual 18


  describe '::renderPreviewAvatars', ->

    it 'should render correct amount of preview avatars', ->

      view = renderIntoDocument(<View participants={@participants}/>)

      previewAvatars = view.renderPreviewAvatars()

      expect(previewAvatars.props.participants.size).toEqual 18


  describe '::renderMoreCount', ->


    it 'should not render show more count part', ->

      participants = mock.getMockParticipants { size: 12 }

      view = renderIntoDocument(<View participants={participants}/>)

      moreCount = view.renderMoreCount()

      expect(moreCount).toNotExist()

