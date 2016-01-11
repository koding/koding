expect = require 'expect'

Reactor = require 'app/flux/base/reactor'

CreateNewChannelParticipantsDropdownVisibilityStore = require 'activity/flux/createchannel/stores/visibilitystore'
actions = require 'activity/flux/createchannel/actions/actiontypes'

describe 'CreateNewChannelParticipantsDropdownVisibilityStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores dropdownVisibility : CreateNewChannelParticipantsDropdownVisibilityStore


  describe '#setVisibility', ->

    it 'sets visibility', ->

      @reactor.dispatch actions.SET_CREATE_NEW_CHANNEL_PARTICIPANTS_DROPDOWN_VISIBILITY, { visible : yes }
      visibility = @reactor.evaluate(['dropdownVisibility'])

      expect(visibility).toBe yes

      @reactor.dispatch actions.SET_CREATE_NEW_CHANNEL_PARTICIPANTS_DROPDOWN_VISIBILITY, { visible : no }
      visibility = @reactor.evaluate(['dropdownVisibility'])

      expect(visibility).toBe no
