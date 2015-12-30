kd             = require 'kd'
expect         = require 'expect'
Machine        = require 'app/providers/machine'
ideRoutes      = require 'ide/routes.coffee'
dataProvider   = require 'app/userenvironmentdataprovider'
mockjaccount   = require './mock.jaccount'
mockjmachine   = require './mock.jmachine'
mockjworkspace = require './mock.jworkspace'

mockMachine    = new Machine { machine: mockjmachine }
{ socialapi }  = kd.singletons


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


  socialapi:

    cacheable:

      toReturnError: ->

        expect.spyOn(socialapi, 'cacheable').andCall (type, id, callback) ->
          callback { message: 'No channel' }


      toReturnChannel: ->

        expect.spyOn(socialapi, 'cacheable').andCall (type, id, callback) ->
          callback null, { id: '6075644514008039523' }



  getMockMachine: ->   return mockMachine

  getMockJMachine: ->  return mockjmachine

  getMockWorkspace: -> return mockjworkspace

  getMockAccount: ->   return mockjaccount
