expect      = require 'expect'
Reactor     = require 'app/flux/base/reactor'
actionTypes = require 'app/flux/environment/actiontypes'
mock        = require '../../../../../../mocks/mockingjay'

ActiveInvitationMachineIdStore  = require 'app/flux/environment/stores/activeinvitationmachineidstore'

machine = mock.getMockMachine()
{ _id } = machine

describe 'ActiveInvitationMachineIdStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores { activeInvitationMachineId : ActiveInvitationMachineIdStore }


  describe '#getInitialState', ->

    it 'should be null', ->

      store = @reactor.evaluate(['activeInvitationMachineId'])

      expect(store).toBe null


  describe '#setMachineId', ->

    it 'should set machine id without force update while if any invitation', ->

      @reactor.dispatch actionTypes.SET_ACTIVE_INVITATION_MACHINE_ID, {
        id : _id
      }

      store = @reactor.evaluate(['activeInvitationMachineId'])

      expect(store).toBe _id


    it 'should remove machine id when the invitation is rejected', ->

      @reactor.dispatch actionTypes.SET_ACTIVE_INVITATION_MACHINE_ID, {
        id : null
      }

      store = @reactor.evaluate(['activeInvitationMachineId'])

      expect(store).toBe null


    it 'should change active machine id when there is already set another machine id', ->

      newMachineId = '569cf9fedc35176690d12421'

      @reactor.dispatch actionTypes.SET_ACTIVE_INVITATION_MACHINE_ID, {
        id : _id
      }

      store = @reactor.evaluate(['activeInvitationMachineId'])

      expect(store).toBe _id

      @reactor.dispatch actionTypes.SET_ACTIVE_INVITATION_MACHINE_ID, {
        id          : newMachineId
        forceUpdate : yes
      }

      store = @reactor.evaluate(['activeInvitationMachineId'])

      expect(store).toBe newMachineId
