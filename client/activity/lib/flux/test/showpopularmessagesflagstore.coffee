expect  = require 'expect'
Reactor = require 'app/flux/base/reactor'
actionTypes = require '../actions/actiontypes'
ShowPopularMessagesFlagStore = require '../stores/showpopularmessagesflagstore'


describe 'ShowPopularMessagesFlagStore', ->

  beforeEach ->
    @reactor = new Reactor
    @reactor.registerStores showPopularMessagesFlag: ShowPopularMessagesFlagStore

  describe '#setFlag', ->

    it 'sets showPopularMessagesFlagStore data as true or false', ->

      showPopularMessagesFlag = yes
      @reactor.dispatch actionTypes.SET_SHOW_POPULAR_MESSAGES_FLAG, { showPopularMessagesFlag }
      flag = @reactor.evaluate ['showPopularMessagesFlag']

      expect(flag).toBe yes


      showPopularMessagesFlag = null
      @reactor.dispatch actionTypes.SET_SHOW_POPULAR_MESSAGES_FLAG, { showPopularMessagesFlag }
      flag = @reactor.evaluate ['showPopularMessagesFlag']

      expect(flag).toBe null

