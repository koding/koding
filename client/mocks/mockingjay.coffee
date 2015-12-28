expect         = require 'expect'
Machine        = require 'app/providers/machine'
dataProvider   = require 'app/userenvironmentdataprovider'
mockjmachine   = require './mock.jmachine'
mockjworkspace = require './mock.jworkspace'

module.exports =

  envDataProvider:

    fetchMachine:

      toReturnMachine: ->

        expect.spyOn(dataProvider, 'fetchMachine').andCall (identifier, callback) ->
          callback new Machine { machine: mockjmachine }


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
