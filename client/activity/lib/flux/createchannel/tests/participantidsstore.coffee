{ expect } = require 'chai'

Reactor = require 'app/flux/base/reactor'

ParticipantIdsStore = require 'activity/flux/createchannel/stores/participantidsstore'
actions = require 'activity/flux/createchannel/actions/actiontypes'

describe 'CreateNewChannelParticipantIdsStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores participantIds : ParticipantIdsStore


  describe '#handleAddParticipantToNewChannel', ->

    it 'sets given accountId to participantidsstore', ->

      testAccountId = 'koding_123'

      @reactor.dispatch actions.ADD_PARTICIPANT_TO_NEW_CHANNEL, { accountId : testAccountId }

      participants = @reactor.evaluate(['participantIds'])

      expect(participants.get testAccountId).to.equal testAccountId


  describe '#handleRemoveParticipantFromNewChannel', ->

    it 'remove given accountId to participantidsstore', ->

      testAccountId_1 = 'koding'
      testAccountId_2 = 'koding_123'

      @reactor.dispatch actions.ADD_PARTICIPANT_TO_NEW_CHANNEL, { accountId : testAccountId_1 }
      @reactor.dispatch actions.ADD_PARTICIPANT_TO_NEW_CHANNEL, { accountId : testAccountId_2 }
      @reactor.dispatch actions.REMOVE_PARTICIPANT_FROM_NEW_CHANNEL, { accountId : testAccountId_1 }

      participants = @reactor.evaluate(['participantIds'])

      expect(participants.get testAccountId_2).to.equal testAccountId_2
      expect(participants.get testAccountId_1).to.be.undefined


  describe '#handleRemoveAllParticipantsFromNewChannel', ->

    it 'removes all participant ids from participantidsstore', ->

      testAccountId_1 = 'koding'
      testAccountId_2 = 'koding_123'

      @reactor.dispatch actions.ADD_PARTICIPANT_TO_NEW_CHANNEL, { accountId : testAccountId_1 }
      @reactor.dispatch actions.ADD_PARTICIPANT_TO_NEW_CHANNEL, { accountId : testAccountId_2 }
      @reactor.dispatch actions.REMOVE_ALL_PARTICIPANTS_FROM_NEW_CHANNEL

      participants = @reactor.evaluate(['participantIds'])

      expect(participants.get testAccountId_1).to.be.undefined
      expect(participants.get testAccountId_2).to.be.undefined

