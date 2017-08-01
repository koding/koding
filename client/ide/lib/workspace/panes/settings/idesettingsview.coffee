kd = require 'kd'



module.exports = class IDESettingsView extends kd.View

  constructor: (options = {}, data) ->

    options.componentId ?= 'terminal'

    super options, data

    @unsetClass 'kdview'

    { name, version } = @getStorageInformation()
    controller        = kd.getSingleton 'appStorageController'
    @appStorage       = controller.storage name, version

    kd.singletons.notificationController.on 'StorageUpdated', =>
      @getSettings yes, no

    @createElements()
    @getSettings()

    @on 'SettingsChanged', @bound 'handleSettingsChanged'


  getSettings: (forceFetch, writeStorage) ->

    settingKeys = @getSettingKeys()

    @appStorage.fetchStorage =>
      @settings = {}

      for key in settingKeys
        value = @appStorage.getValue key
        @settings[key] = value ? @defaults[key]

      @setSettings writeStorage
      @emit 'SettingsFetched'

    , forceFetch


  setSettings: (writeStorage) ->

    for own key, value of @settings

      @[key].setDefaultValue value

      { componentId } = @getOptions()
      appManager      = kd.getSingleton 'appManager'
      appManager.tell 'IDE', 'updateSettings', componentId, key, value, writeStorage


  handleSettingsChanged: (key, value) ->

    @appStorage.setValue key, value, null, null, yes
