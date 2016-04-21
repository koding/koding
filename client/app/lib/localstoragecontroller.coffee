getAppVersion = require './util/getAppVersion'
kd = require 'kd'
KDController = kd.Controller
LocalStorage = require './localstorage'


module.exports = class LocalStorageController extends KDController

  constructor: ->
    super
    @localStorages = {}

  storage: (appName, version) ->

    version ?= (getAppVersion appName) or '1.0'

    key = "#{appName}-#{version}"
    return @localStorages[key] or= new LocalStorage appName, version

# Let people can use AppStorage
