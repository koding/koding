kd = require 'kd'
filenames = require './tests/filenames'
AppView = require './AppView'
module.exports = class TestRunnerAppController extends kd.ViewController

  kd.registerAppClass this, { name : 'TestRunner' }


  constructor: (options = {}, data) ->

    { currentPath } = kd.singletons.router

    options.view = new AppView {}, filenames

    super options, data

