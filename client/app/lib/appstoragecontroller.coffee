kd = require 'kd'
KDController = kd.Controller
AppStorage = require './appstorage'


module.exports = class AppStorageController extends KDController

  constructor:->
    super
    @appStorages = {}

  storage:(appName, version = "1.0")->
    key = "#{appName}-#{version}"
    @appStorages[key] or= new AppStorage appName, version
    storage = @appStorages[key]
    storage.fetchStorage()
    return storage

# Let people can use AppStorage

