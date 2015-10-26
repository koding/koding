{ expect } = require 'chai'

Reactor = require 'app/flux/base/reactor'

ChatInputSearchStore = require 'activity/flux/chatinput/stores/search/searchstore'
actionTypes = require 'activity/flux/chatinput/actions/actiontypes'

describe 'ChatInputSearchStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores chatInputSearchItems : ChatInputSearchStore


  describe '#handleSuccess', ->

    it 'receives fetched list', ->

      message1 = 'message 1'
      message2 = 'message 2'
      message3 = 'message 3'
      items = [
        { id : '1', body : message1 }
        { id : '2', body : message2 }
      ]
      stateId = '123'

      @reactor.dispatch actionTypes.CHAT_INPUT_SEARCH_SUCCESS, { stateId, items }
      searchItems = @reactor.evaluate(['chatInputSearchItems']).get stateId

      expect(searchItems.size).to.equal items.length
      expect(searchItems.get(0).get('body')).to.equal message1
      expect(searchItems.get(1).get('body')).to.equal message2

      items = [
        { id : '3', body : message3 }
      ]
      @reactor.dispatch actionTypes.CHAT_INPUT_SEARCH_SUCCESS, { stateId, items }
      searchItems = @reactor.evaluate(['chatInputSearchItems']).get stateId

      expect(searchItems.size).to.equal items.length
      expect(searchItems.get(0).get('body')).to.equal message3


  describe '#handleReset', ->

    message1 = 'message 1'
    message2 = 'message 2'
    items = [
      { id : '1', body : message1 }
      { id : '2', body : message2 }
    ]
    stateId = '123'

    it 'resets store data', ->

      @reactor.dispatch actionTypes.CHAT_INPUT_SEARCH_SUCCESS, { stateId, items }

      @reactor.dispatch actionTypes.CHAT_INPUT_SEARCH_RESET, { stateId }
      searchItems = @reactor.evaluate(['chatInputSearchItems']).get stateId

      expect(searchItems).to.be.undefined

    it 'handles fetch data failure', ->

      @reactor.dispatch actionTypes.CHAT_INPUT_SEARCH_SUCCESS, { stateId, items }

      @reactor.dispatch actionTypes.CHAT_INPUT_SEARCH_FAIL, { stateId }
      searchItems = @reactor.evaluate(['chatInputSearchItems']).get stateId

      expect(searchItems).to.be.undefined

