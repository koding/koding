kd           = require 'kd'
AppStorage   = require './appstorage'

module.exports = class AppStorageController extends kd.Controller

  constructor: ->

    super

    @appStorages = {}


  storage: (name, version) ->

    if 'object' is typeof name
      opts = name
    else
      opts =
        name    : name
        version : version or AppStorage.DEFAULT_VERSION

    throwString = 'storage name must be provided'
    throw throwString  unless 'string' is typeof opts.name

    key = "#{opts.name}-#{opts.version}"

    storage = @appStorages[key] or= new AppStorage opts.name, opts.version

    return storage
