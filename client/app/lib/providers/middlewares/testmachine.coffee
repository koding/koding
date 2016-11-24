{ assign } = require 'lodash'
isTestMachine = require 'app/util/isTestMachine'
MemoryFsKlient = require 'app/kite/kites/memoryfsklient'


# defines middleware methods to be used with given classes.
# it uses `runMiddlewares` util to achieve that purpose
# basically, methods accepting a completion callback will be run through
# `async` middlewares.
#
# This middleware's specific purpose is to provide a mock machine
# implementation to be used by IDE instances, so that, we can run tests without
# thinking about making network requests.
module.exports = TestMachineMiddleware =

  Machine:
    getBaseKite: ->
      if isTestMachine @getData()
        return @_mockKlient  if @_mockKlient
        @_mockKlient = new MemoryFsKlient
        @_mockKlient.setTransport()
        return @_mockKlient

  ComputeController:
    create: (options, callback) ->
      Machine = require 'app/providers/machine'
      if isTestMachine options.machine
        @_testMachine = new Machine { machine: options.machine }
        return callback null, assign {}, options, { shouldStop: yes }

      return callback null, options

    fetchStacks: (stacks) ->
      stacks.map (stack) =>
        if stack.title is 'Managed VMs'
          if @_testMachine and not (@_testMachine in stack.machines)
            stack.machines.push @_testMachine

        return stack


  EnvironmentDataProvider:
    setDefaults_: (data) ->
      if @_testMachine and not (@_testMachine in data.own)
      then assign {}, data, { own: data.own.concat [@_testMachine] }
      else data


