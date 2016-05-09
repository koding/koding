kd                        = require 'kd'
expect                    = require 'expect'
remote                    = require('app/remote').getInstance()
FSFile                    = require 'app/util/fs/fsfile'
Machine                   = require 'app/providers/machine'
ideRoutes                 = require 'ide/routes.coffee'
mockjgroup                = require './mock.jgroup'
mockjstack                = require './mock.jstack'
mockjmachine              = require './mock.jmachine'
mockjaccount              = require './mock.jaccount'
mockjcredential           = require './mock.jcredential'
dataProvider              = require 'app/userenvironmentdataprovider'
mockMessage               = require 'app/util/generateDummyMessage'
toImmutable               = require 'app/util/toImmutable'
mockThread                = require 'app/util/generateDummyThread'
mockChannel               = require 'app/util/generateDummyChannel'
mockjworkspace            = require './mock.jworkspace'
mockjcomputestack         = require './mock.jcomputestack'
mockjinvitation           = require './mock.jinvitation'
mockParticipants          = require 'app/util/generateDummyParticipants'
mockReactComponent        = require './mock.reactComponent'
mockcollaborationchannel  = require './mock.collaborationchannel'
mockMessages              = require 'app/util/generateDummyMessages'
mockChannels              = require 'app/util/generateDummyChannels'
draftStackTemplate        = require './mock.draftStackTemplate'
teamStackTemplate         = require './mock.teamStackTemplate'
privateStackTemplate      = require './mock.privateStackTemplate'
teamMemberWithRole        = require './mock.teamMembersWithRole'
teamSendInvites           = require './mock.teamSendInvites'


mockMachine = new Machine { machine: mockjmachine }
mockGroup   = remote.revive mockjgroup

{ socialapi, appManager } = kd.singletons


module.exports =

  envDataProvider:


    fetchMachine:

      toReturnMachine: ->

        expect.spyOn(dataProvider, 'fetchMachine').andCall (identifier, callback) ->
          callback mockMachine


      toReturnNull: ->

        expect.spyOn(dataProvider, 'fetchMachine').andCall (identifier, callback) ->
          callback null


    ensureDefaultWorkspace: ->

      expect.spyOn(dataProvider, 'ensureDefaultWorkspace').andCall (callback) ->
        callback()

    fetch:

      toReturnMockMachineAndWorkspace: ->

        { machine : mockjmachine, workspaces : [ mockjworkspace ] }


      toReturnLoadDataWithCollaborationMachine: ->

        item = @toReturnMockMachineAndWorkspace()

        return {
          collaboration : [ item ]
          shared        : []
          own           : []
        }


      toReturnLoadDataWithSharedMachine: ->

        item = @toReturnMockMachineAndWorkspace()

        return {
          collaboration : []
          shared        : [ item ]
          own           : []
        }


      toReturnLoadDataWithOwnMachine: ->

        item = @toReturnMockMachineAndWorkspace()

        return {
          collaboration : []
          shared        : []
          own           : [ item ]
        }


    fetchWorkspaceByMachineUId:

      toReturnWorkspace: ->

        expect.spyOn(dataProvider, 'fetchWorkspaceByMachineUId').andCall (options, callback) ->
          callback mockjworkspace


      toReturnNull: ->

        expect.spyOn(dataProvider, 'fetchWorkspaceByMachineUId').andCall (options, callback) ->
          callback null


    findWorkspace:

      toReturnWorkspace: ->

        expect.spyOn(dataProvider, 'findWorkspace').andCall -> return mockjworkspace


      toReturnNull: ->

        expect.spyOn(dataProvider, 'findWorkspace').andCall -> return null


    getMyMachines:

      toReturnMachines: ->

        expect.spyOn(dataProvider, 'getMyMachines').andCall -> return [ { machine: mockMachine } ]


      toReturnEmptyArray: ->

        expect.spyOn(dataProvider, 'getMyMachines').andCall -> return []


    fetchMachineByLabel:

      toReturnMachine: ->

        expect.spyOn(dataProvider, 'fetchMachineByLabel').andCall (identifier, callback) ->
          callback mockMachine


      toReturnMachineAndWorkspace: ->

        expect.spyOn(dataProvider, 'fetchMachineByLabel').andCall (identifier, callback) ->
          callback mockMachine, mockjworkspace


      toReturnNull: ->

        expect.spyOn(dataProvider, 'fetchMachineByLabel').andCall (identifier, callback) ->
          callback null, null


    fetchMachineAndWorkspaceByChannelId:

      toReturnMachineAndWorkspace: ->

        expect.spyOn(dataProvider, 'fetchMachineAndWorkspaceByChannelId').andCall (channelId, callback) ->
          callback mockMachine, mockjworkspace


      toReturnNull: ->

        expect.spyOn(dataProvider, 'fetchMachineAndWorkspaceByChannelId').andCall (channelId, callback) ->
          callback null, null


  machine:

    isPermanent:

      toReturnYes: -> expect.spyOn(mockMachine, 'isPermanent').andCall -> return yes

      toReturnNo:  -> expect.spyOn(mockMachine, 'isPermanent').andCall -> return no


  ideRoutes:

    getLatestWorkspace:

      toReturnWorkspace: ->

        expect.spyOn(ideRoutes, 'getLatestWorkspace').andCall ->
          return { workspaceSlug: 'foo-workspace', machineLabel: 'koding-vm-0' }


      toReturnNull: ->

        expect.spyOn(ideRoutes, 'getLatestWorkspace').andCall -> return null


      toReturnWorkspaceWithChannelId: ->

        expect.spyOn(ideRoutes, 'getLatestWorkspace').andCall ->
          return { workspaceSlug: 'foo-workspace', channelId: '6075644514008039523', machineLabel: 'koding-vm-0' }


    findInstance:

      toReturnInstance: ->

        expect.spyOn(ideRoutes, 'findInstance').andCall -> return {}


      toReturnNull: ->

        expect.spyOn(ideRoutes, 'findInstance').andCall -> return null


  socialapi:

    cacheable:

      toReturnError: ->

        expect.spyOn(socialapi, 'cacheable').andCall (type, id, callback) ->
          callback { message: 'No channel' }


      toReturnChannel: ->

        expect.spyOn(socialapi, 'cacheable').andCall (type, id, callback) ->
          callback null, { id: '6075644514008039523' }


  groups:

    getCurrentGroup:

      toReturnGroup: ->

        { groupsController } = kd.singletons

        expect.spyOn(groupsController, 'getCurrentGroup').andReturn mockGroup


  search:

    getIndex:

      toReturnIndex: (success = yes) ->

        { search } = kd.singletons

        expect.spyOn(search, 'getIndex').andReturn {
          search : (seed, callback, options) ->
            objectID    = mockjaccount._id
            { profile } = mockjaccount
            { firstName, lastName } = profile

            callback success, {
              hits : [
                { objectID, firstName, lastName, nick: profile.nickname }
              ]
            }
        }


  remote:

    cacheableAsync:

      toReturnPassedParam: (param) ->

        new Promise (resolve, reject) ->

          promise = new Promise (resolve, reject) -> resolve param

          expect.spyOn(remote, 'cacheableAsync').andReturn promise


    api:

      JAccount:

        some:

          toReturnError: ->

            expect.spyOn(remote.api.JAccount, 'some').andCall (query, options, callback) ->
              callback { some: 'error' }


          toReturnAccounts: ->

            expect.spyOn(remote.api.JAccount, 'some').andCall (query, options, callback) ->
              callback null, [ mockjaccount ]

        one:

          toReturnAccount: ->

            new Promise (resolve, reject) ->

              promise = new Promise (resolve, reject) -> resolve mockjaccount

              expect.spyOn(remote.api.JAccount, 'one').andReturn promise


  appManager:

    getFrontApp:

      toReturnPassedParam: (param) ->

        expect.spyOn(appManager, 'getFrontApp').andReturn param


  fsFile:

    fetchPermissions:

      toReturnError: (error = { some: 'error' }) ->

        expect.spyOn(FSFile.prototype, 'fetchPermissions').andCall (callback) ->
          callback error


      toReturnInfo: (readable = yes, writable = yes) ->

        expect.spyOn(FSFile.prototype, 'fetchPermissions').andCall (callback) ->
          callback null, { readable, writable }


  getMockMachine: ->   return mockMachine

  getMockJMachine: ->  return mockjmachine

  getMockWorkspace: -> return mockjworkspace

  getMockAccount: ->   return mockjaccount

  getMockGroup: ->     return mockGroup

  getMockJCredential: -> return mockjcredential

  getMockCredential: -> return remote.revive mockjcredential

  getMockImmutableMachine : -> return toImmutable mockMachine

  getMockImmutableWorkspace : -> return toImmutable mockjworkspace

  getMockCollaborationChannel : -> return mockcollaborationchannel

  getMockJComputeStack: -> return mockjcomputestack

  getMockComputeStack: -> remote.revive mockjcomputestack

  getMockJStack: -> mockjstack

  getMockStack: -> remote.revive mockjstack

  getMockJInvitation: -> mockjinvitation

  getMockInvitation: -> remote.revive mockjinvitation

  getMockMessage: (args...) -> return mockMessage(args...)

  getMockChannel: (args...) -> return mockChannel(args...)

  getMockChannels: (args...) -> return mockChannels(args...)

  getMockThread: (args...)  -> return mockThread(args...)

  getMockParticipants: (args...) -> return mockParticipants(args...)

  getMockReactComponent: -> return new mockReactComponent

  getMockMessages: (args...) -> return mockMessages(args...)

  getDraftStackTemplate: -> return draftStackTemplate

  getTeamStackTemplate: -> return teamStackTemplate

  getPrivateStackTemplate: -> return privateStackTemplate
  
  getTeamMembersWithRole: -> return teamMemberWithRole
  
  getTeamSendInvites: -> return teamSendInvites
  