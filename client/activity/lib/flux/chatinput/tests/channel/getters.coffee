expect  = require 'expect'
Reactor = require 'app/flux/base/reactor'
React   = require 'kd-react'

ActivityActionTypes    = require 'activity/flux/actions/actiontypes'
ChannelsStore          = require 'activity/flux/stores/channelsstore'
PopularChannelIdsStore = require 'activity/flux/stores/popularchannelidsstore'

ChatInputFlux        = require 'activity/flux/chatinput'
ChatInputActionTypes = require 'activity/flux/chatinput/actions/actiontypes'
DropboxSettingsStore = require 'activity/flux/chatinput/stores/dropboxsettingsstore'

describe 'ChatInputChannelGetters', ->

  channels = [
    { id : 'public', name : 'public', typeConstant: 'group' }
    { id : 'qwerty', name : 'qwerty', typeConstant: 'topic' }
    { id : 'qwerty2', name : 'qwerty2', typeConstant: 'topic' }
    { id : 'qwerty3', name : 'qwerty3', typeConstant: 'privatemessage' }
    { id : 'koding', name : 'koding', typeConstant: 'topic' }
    { id : 'whoa', name : 'whoa', typeConstant: 'privatemessage' }
  ]
  popularChannels = [ channels[1], channels[4] ]
  stateId = '123'
  config  = {
    component       : React.Component
    getters         :
      items         : 'dropboxChannels'
      selectedIndex : 'channelsSelectedIndex'
      selectedItem  : 'channelsSelectedItem'
  }
  testConfig = {
    component       : React.Component
    getters         :
      items         : 'dropboxTestItems'
      selectedIndex : 'testSelectedIndex'
      selectedItem  : 'testSelectedItem'
  }

  beforeEach ->

    @reactor = new Reactor
    stores   = {}
    stores[ChannelsStore.getterPath] = ChannelsStore
    stores[PopularChannelIdsStore.getterPath] = PopularChannelIdsStore
    stores[DropboxSettingsStore.getterPath] = DropboxSettingsStore
    @reactor.registerStores stores

    for channel in channels
      @reactor.dispatch ActivityActionTypes.LOAD_CHANNEL_SUCCESS, { channel }

    @reactor.dispatch ActivityActionTypes.LOAD_POPULAR_CHANNELS_SUCCESS, { channels : popularChannels }


  describe '#dropboxChannels', ->

    it 'returns nothing if drobox config doesn\'t contain dropboxChannels getter', ->

      { getters } = ChatInputFlux

      items = @reactor.evaluate getters.dropboxChannels stateId
      expect(items).toBeA 'undefined'

      @reactor.dispatch ChatInputActionTypes.SET_DROPBOX_QUERY_AND_CONFIG, { stateId, query : '', config : testConfig }

      items = @reactor.evaluate getters.dropboxChannels stateId
      expect(items).toBeA 'undefined'


    it 'returns popular channels if query is empty', ->

      { getters } = ChatInputFlux

      @reactor.dispatch ChatInputActionTypes.SET_DROPBOX_QUERY_AND_CONFIG, { stateId, query : '', config }
      items = @reactor.evaluateToJS getters.dropboxChannels stateId

      expect(items).toEqual popularChannels


    it 'returns public channels filtered by query if query isn\'t empty', ->

      { getters } = ChatInputFlux

      @reactor.dispatch ChatInputActionTypes.SET_DROPBOX_QUERY_AND_CONFIG, { stateId, query : 'qwerty', config }
      items = @reactor.evaluateToJS getters.dropboxChannels stateId

      filteredItems = [ channels[1], channels[2] ]

      expect(items).toEqual filteredItems


  describe '#channelsSelectedIndex', ->

     it 'returns -1 if channels are empty', ->

      { getters } = ChatInputFlux

      @reactor.dispatch ChatInputActionTypes.SET_DROPBOX_QUERY_AND_CONFIG, { stateId, query : '', config : testConfig }
      index = @reactor.evaluate getters.channelsSelectedIndex stateId

      expect(index).toBe -1


   it 'returns 0 by default', ->

      { getters } = ChatInputFlux

      @reactor.dispatch ChatInputActionTypes.SET_DROPBOX_QUERY_AND_CONFIG, { stateId, query : '', config }
      index = @reactor.evaluate getters.channelsSelectedIndex stateId

      expect(index).toBe 0


    it 'returns index which was set before', ->

      index = 1
      { getters } = ChatInputFlux

      @reactor.dispatch ChatInputActionTypes.SET_DROPBOX_QUERY_AND_CONFIG, { stateId, query : '', config }
      @reactor.dispatch ChatInputActionTypes.SET_DROPBOX_SELECTED_INDEX, { stateId, index }

      selectedIndex = @reactor.evaluate getters.channelsSelectedIndex stateId

      expect(selectedIndex).toBe index


    it 'returns index corrected to items size if index is greater that items size', ->

      { getters } = ChatInputFlux

      @reactor.dispatch ChatInputActionTypes.SET_DROPBOX_QUERY_AND_CONFIG, { stateId, query : '', config }

      items = @reactor.evaluate getters.dropboxChannels stateId

      @reactor.dispatch ChatInputActionTypes.SET_DROPBOX_SELECTED_INDEX, { stateId, index : items.size - 1 }
      @reactor.dispatch ChatInputActionTypes.MOVE_TO_NEXT_DROPBOX_SELECTED_INDEX, { stateId }

      selectedIndex = @reactor.evaluate getters.channelsSelectedIndex stateId

      expect(selectedIndex).toBe 0


    it 'returns index corrected to items size if index is negative', ->

      { getters } = ChatInputFlux

      @reactor.dispatch ChatInputActionTypes.SET_DROPBOX_QUERY_AND_CONFIG, { stateId, query : '', config }
      # index is set by default to 0
      @reactor.dispatch ChatInputActionTypes.MOVE_TO_PREV_DROPBOX_SELECTED_INDEX, { stateId }

      items = @reactor.evaluate getters.dropboxChannels stateId
      selectedIndex = @reactor.evaluate getters.channelsSelectedIndex stateId

      expect(selectedIndex).toBe items.size - 1


  describe '#channelsSelectedItem', ->

    it 'returns nothing if channels are empty', ->

      { getters } = ChatInputFlux

      @reactor.dispatch ChatInputActionTypes.SET_DROPBOX_QUERY_AND_CONFIG, { stateId, query : '', config : testConfig }
      selectedItem = @reactor.evaluate getters.channelsSelectedItem stateId

      expect(selectedItem).toBeA 'undefined'


    it 'returns item by selected index', ->

      { getters } = ChatInputFlux

      @reactor.dispatch ChatInputActionTypes.SET_DROPBOX_QUERY_AND_CONFIG, { stateId, query : '', config }
      @reactor.dispatch ChatInputActionTypes.SET_DROPBOX_SELECTED_INDEX, { stateId, index : 1 }

      selectedItem = @reactor.evaluateToJS getters.channelsSelectedItem stateId

      expect(selectedItem).toEqual channels[4]

