expect         = require 'expect'
Machine        = require 'app/providers/machine'
dataProvider   = require 'app/userenvironmentdataprovider'
mockjmachine   = require './mock.jmachine'
mockjworkspace = require './mock.jworkspace'
mockMachine    = new Machine { machine: mockjmachine }

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


  machine:

    isPermanent:

      toReturnYes: -> expect.spyOn(mockMachine, 'isPermanent').andCall -> return yes

      toReturnNo:  -> expect.spyOn(mockMachine, 'isPermanent').andCall -> return no


  getMockMachine: ->  return mockMachine

  getMockJMachine: -> return mockjmachine

  getMockWorkspace: -> return mockjworkspace
