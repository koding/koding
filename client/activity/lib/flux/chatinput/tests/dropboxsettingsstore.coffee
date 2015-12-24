expect  = require 'expect'
Reactor = require 'app/flux/base/reactor'
React   = require 'kd-react'

actionTypes = require 'activity/flux/chatinput/actions/actiontypes'

ChatInputDropboxSettingsStore = require 'activity/flux/chatinput/stores/dropboxsettingsstore'

describe 'ChatInputDropboxSettingsStore', ->

  stateId = '123'
  query   = 'test'
  config  = {
    component : React.Component
    getters   :
      items   : 'testItems'
  }

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores dropboxSettings : ChatInputDropboxSettingsStore


  describe '#setQueryAndConfig', ->

    it 'sets query and config', ->

      @reactor.dispatch actionTypes.SET_DROPBOX_QUERY_AND_CONFIG, { stateId, query, config }
      dropboxSettings = @reactor.evaluate(['dropboxSettings']).get stateId

      expect(dropboxSettings.get 'query').toBe query
      expect(dropboxSettings.get('config').toJS()).toEqual config
      expect(dropboxSettings.get 'index').toBe 0


  describe '#setIndex', ->

    it 'can\'t set index if config was not set yet', ->

      index = 1
      @reactor.dispatch actionTypes.SET_DROPBOX_SELECTED_INDEX, { stateId, index }
      dropboxSettings = @reactor.evaluate(['dropboxSettings']).get stateId

      expect(dropboxSettings.get 'index').toBeA 'undefined'


    it 'sets index successfully', ->

      index = 1
      @reactor.dispatch actionTypes.SET_DROPBOX_QUERY_AND_CONFIG, { stateId, query, config }
      @reactor.dispatch actionTypes.SET_DROPBOX_SELECTED_INDEX, { stateId, index }
      dropboxSettings = @reactor.evaluate(['dropboxSettings']).get stateId

      expect(dropboxSettings.get 'index').toBe index

      index = 3
      @reactor.dispatch actionTypes.SET_DROPBOX_SELECTED_INDEX, { stateId, index }
      dropboxSettings = @reactor.evaluate(['dropboxSettings']).get stateId

      expect(dropboxSettings.get 'index').toBe index


  describe '#moveToNextIndex', ->

    it 'can\'t move to next index if config was not set yet', ->

      index = 3

      @reactor.dispatch actionTypes.MOVE_TO_NEXT_DROPBOX_SELECTED_INDEX, { stateId }
      dropboxSettings = @reactor.evaluate(['dropboxSettings']).get stateId

      expect(dropboxSettings.get 'index').toBeA 'undefined'


  	it 'moves to next index successfully', ->

      index = 3
      nextIndex = index + 1

      @reactor.dispatch actionTypes.SET_DROPBOX_QUERY_AND_CONFIG, { stateId, query, config }
      @reactor.dispatch actionTypes.SET_DROPBOX_SELECTED_INDEX, { stateId, index }
      @reactor.dispatch actionTypes.MOVE_TO_NEXT_DROPBOX_SELECTED_INDEX, { stateId }
      dropboxSettings = @reactor.evaluate(['dropboxSettings']).get stateId

      expect(dropboxSettings.get 'index').toBe nextIndex
      

  describe '#moveToPrevIndex', ->

    it 'can\'t move to prev index if config was not set yet', ->

      index = 3

      @reactor.dispatch actionTypes.MOVE_TO_PREV_DROPBOX_SELECTED_INDEX, { stateId }
      dropboxSettings = @reactor.evaluate(['dropboxSettings']).get stateId

      expect(dropboxSettings.get 'index').toBeA 'undefined'


  	it 'moves to prev index successfully', ->

      index = 3
      prevIndex = index - 1

      @reactor.dispatch actionTypes.SET_DROPBOX_QUERY_AND_CONFIG, { stateId, query, config }
      @reactor.dispatch actionTypes.SET_DROPBOX_SELECTED_INDEX, { stateId, index }
      @reactor.dispatch actionTypes.MOVE_TO_PREV_DROPBOX_SELECTED_INDEX, { stateId }
      dropboxSettings = @reactor.evaluate(['dropboxSettings']).get stateId

      expect(dropboxSettings.get 'index').toBe prevIndex


  describe '#reset', ->

    it 'resets dropbox settings', ->

      index = 5

      @reactor.dispatch actionTypes.SET_DROPBOX_QUERY_AND_CONFIG, { stateId, query, config }
      @reactor.dispatch actionTypes.SET_DROPBOX_SELECTED_INDEX, { stateId, index }
      @reactor.dispatch actionTypes.RESET_DROPBOX, { stateId }
      dropboxSettings = @reactor.evaluate(['dropboxSettings']).get stateId

      expect(dropboxSettings).toBeA 'undefined'

