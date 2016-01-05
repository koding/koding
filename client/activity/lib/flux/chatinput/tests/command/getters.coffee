expect  = require 'expect'
Reactor = require 'app/flux/base/reactor'
React   = require 'kd-react'

ActivityActionTypes          = require 'activity/flux/actions/actiontypes'
ChannelsStore                = require 'activity/flux/stores/channelsstore'
SelectedChannelThreadIdStore = require 'activity/flux/stores/selectedchannelthreadidstore'

ChatInputFlux        = require 'activity/flux/chatinput'
ChatInputActionTypes = require 'activity/flux/chatinput/actions/actiontypes'
DropboxSettingsStore = require 'activity/flux/chatinput/stores/dropboxsettingsstore'
CommandsStore        = require 'activity/flux/chatinput/stores/command/commandsstore'

describe 'ChatInputCommandGetters', ->

  privateChannel = { id : 'whoa', name : 'whoa', typeConstant: 'privatemessage' }
  topicChannel   = { id : 'qwerty', name : 'qwerty', typeConstant: 'topic' }

  stateId = '123'
  config  = {
    component       : React.Component
    getters         :
      items         : 'dropboxCommands'
      selectedIndex : 'commandsSelectedIndex'
      selectedItem  : 'commandsSelectedItem'
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
    stores[SelectedChannelThreadIdStore.getterPath] = SelectedChannelThreadIdStore
    stores[DropboxSettingsStore.getterPath] = DropboxSettingsStore
    stores[CommandsStore.getterPath] = CommandsStore
    @reactor.registerStores stores

    @reactor.dispatch ActivityActionTypes.LOAD_CHANNEL_SUCCESS, { channel : privateChannel }
    @reactor.dispatch ActivityActionTypes.LOAD_CHANNEL_SUCCESS, { channel : topicChannel }

    @reactor.dispatch ActivityActionTypes.SET_SELECTED_CHANNEL_THREAD, { channelId : topicChannel.id }


  describe '#dropboxCommands', ->

    it 'returns nothing if drobox config doesn\'t contain dropboxCommands getter', ->

      { getters } = ChatInputFlux

      items = @reactor.evaluate getters.dropboxCommands stateId
      expect(items).toBeA 'undefined'

      @reactor.dispatch ChatInputActionTypes.SET_DROPBOX_QUERY_AND_CONFIG, { stateId, query : '', config : testConfig }

      items = @reactor.evaluate getters.dropboxCommands stateId
      expect(items).toBeA 'undefined'


    it 'returns all available commands if query is empty', ->

      { getters } = ChatInputFlux

      @reactor.dispatch ChatInputActionTypes.SET_DROPBOX_QUERY_AND_CONFIG, { stateId, query : '', config }
      items = @reactor.evaluateToJS getters.dropboxCommands stateId
      allCommands = @reactor.evaluateToJS [ CommandsStore.getterPath ]

      expect(items).toEqual allCommands


    it 'excludes /search command if selected channel is private', ->

      { getters } = ChatInputFlux

      @reactor.dispatch ChatInputActionTypes.SET_DROPBOX_QUERY_AND_CONFIG, { stateId, query : '', config }
      @reactor.dispatch ActivityActionTypes.SET_SELECTED_CHANNEL_THREAD, { channelId : privateChannel.id }
      items = @reactor.evaluateToJS getters.dropboxCommands stateId
      items = items.map (item) -> item.name

      expect(items.length).toBeGreaterThan 0
      expect(items).toExclude '/search'


    it 'returns commands filtered by query if query isn\'t empty', ->

      { getters } = ChatInputFlux

      @reactor.dispatch ChatInputActionTypes.SET_DROPBOX_QUERY_AND_CONFIG, { stateId, query : '/inv', config }
      items = @reactor.evaluateToJS getters.dropboxCommands stateId
      items = items.map (item) -> item.name

      expect(items.length).toBe 1
      expect(items[0]).toBe '/invite'

      @reactor.dispatch ChatInputActionTypes.SET_DROPBOX_QUERY_AND_CONFIG, { stateId, query : '/le', config }
      items = @reactor.evaluateToJS getters.dropboxCommands stateId
      items = items.map (item) -> item.name

      expect(items.length).toBe 1
      expect(items[0]).toBe '/leave'


  describe '#commandsSelectedIndex', ->

     it 'returns -1 if commands are empty', ->

      { getters } = ChatInputFlux

      @reactor.dispatch ChatInputActionTypes.SET_DROPBOX_QUERY_AND_CONFIG, { stateId, query : '', config : testConfig }
      index = @reactor.evaluate getters.commandsSelectedIndex stateId

      expect(index).toBe -1


   it 'returns 0 by default', ->

      { getters } = ChatInputFlux

      @reactor.dispatch ChatInputActionTypes.SET_DROPBOX_QUERY_AND_CONFIG, { stateId, query : '', config }
      index = @reactor.evaluate getters.commandsSelectedIndex stateId

      expect(index).toBe 0


    it 'returns index which was set before', ->

      index = 2
      { getters } = ChatInputFlux

      @reactor.dispatch ChatInputActionTypes.SET_DROPBOX_QUERY_AND_CONFIG, { stateId, query : '', config }
      @reactor.dispatch ChatInputActionTypes.SET_DROPBOX_SELECTED_INDEX, { stateId, index }

      selectedIndex = @reactor.evaluate getters.commandsSelectedIndex stateId

      expect(selectedIndex).toBe index


    it 'returns index corrected to items size if index is greater that items size', ->

      { getters } = ChatInputFlux

      @reactor.dispatch ChatInputActionTypes.SET_DROPBOX_QUERY_AND_CONFIG, { stateId, query : '', config }

      items = @reactor.evaluate getters.dropboxCommands stateId

      @reactor.dispatch ChatInputActionTypes.SET_DROPBOX_SELECTED_INDEX, { stateId, index : items.size - 1 }
      @reactor.dispatch ChatInputActionTypes.MOVE_TO_NEXT_DROPBOX_SELECTED_INDEX, { stateId }

      selectedIndex = @reactor.evaluate getters.commandsSelectedIndex stateId

      expect(selectedIndex).toBe 0


    it 'returns index corrected to items size if index is negative', ->

      { getters } = ChatInputFlux

      @reactor.dispatch ChatInputActionTypes.SET_DROPBOX_QUERY_AND_CONFIG, { stateId, query : '', config }
      # index is set by default to 0
      @reactor.dispatch ChatInputActionTypes.MOVE_TO_PREV_DROPBOX_SELECTED_INDEX, { stateId }

      items = @reactor.evaluate getters.dropboxCommands stateId
      selectedIndex = @reactor.evaluate getters.commandsSelectedIndex stateId

      expect(selectedIndex).toBe items.size - 1


  describe '#commandsSelectedItem', ->

    it 'returns nothing if commands are empty', ->

      { getters } = ChatInputFlux

      @reactor.dispatch ChatInputActionTypes.SET_DROPBOX_QUERY_AND_CONFIG, { stateId, query : '', config : testConfig }
      selectedItem = @reactor.evaluate getters.commandsSelectedItem stateId

      expect(selectedItem).toBeA 'undefined'


    it 'returns item by selected index', ->

      { getters } = ChatInputFlux

      @reactor.dispatch ChatInputActionTypes.SET_DROPBOX_QUERY_AND_CONFIG, { stateId, query : '', config }
      @reactor.dispatch ChatInputActionTypes.SET_DROPBOX_SELECTED_INDEX, { stateId, index : 1 }

      items = @reactor.evaluateToJS getters.dropboxCommands stateId
      selectedItem = @reactor.evaluateToJS getters.commandsSelectedItem stateId

      expect(selectedItem).toEqual items[1]

