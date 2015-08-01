{ expect } = require 'chai'

Reactor = require 'app/flux/reactor'

EmojisStore = require 'activity/flux/stores/emojis/emojisstore'
actionTypes = require 'activity/flux/actions/actiontypes'

describe 'EmojisStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores emojis : EmojisStore


  it 'checks that emojis are not empty', ->

      emoji1 = 'smile'
      emoji2 = 'beer'

      emojis = @reactor.evaluate ['emojis']

      expect(emojis.indexOf emoji1).to.be.above -1
      expect(emojis.indexOf emoji2).to.be.above -1
