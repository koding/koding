class Registry
  constructor: (@suite) ->

  runTests: ->
    test() for test in tests for tests in @suite

module.exports = new Registry [
  (require './Main/formworkflow')
]