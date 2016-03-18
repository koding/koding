Machine = require './machine'
Promise = require 'bluebird'

module.exports = class DummyMachine extends Machine

  constructor: (options = {}) ->

    @label = 'Dummy'
    @uid   = 'dummy'

    @kites   =
      klient :
        init : -> Promise.reject()
