kd           = require 'kd'
AppStorage   = require './appstorage'

module.exports =

class AppStorageController extends kd.Controller

  DEFAULT_VERSION   = '1.0'
  FETCH_IMMEDIATELY = yes

  constructor: ->

    super

    @appStorages = {}


  storage: (name, version) ->

    if 'object' is typeof name then opts = name
    else
      opts =
        name    : name
        version : version or DEFAULT_VERSION

    throw 'storage name must be provided'  unless 'string' is typeof opts.name

    opts.fetch = FETCH_IMMEDIATELY  unless opts.fetch is false

    key = "#{name}-#{version}"

    storage = @appStorages[key] or= new AppStorage opts.name, opts.version
    storage.fetchStorage()  if opts.fetch?

    return storage
