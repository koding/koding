kd = require 'kd'
JView = require 'app/jview'


module.exports = class IDESettingsView extends JView

  constructor: (options = {}, data) ->

    options.componentId ?= 'terminal'

    super options, data

    @unsetClass 'kdview'

    {name, version} = @getStorageInformation()
    controller      = kd.getSingleton 'appStorageController'
    @appStorage     = controller.storage name, version

    @createElements()
    @getSettings()

    @on 'SettingsFetched', @bound 'setSettings'
    @on 'SettingsChanged', @bound 'handleSettingsChanged'


  getSettings: ->

    settingKeys = @getSettingKeys()

    @appStorage.fetchStorage =>
      @settings = {}

      for key in settingKeys
        value = @appStorage.getValue key
        @settings[key] = value ? @defaults[key]

      @emit 'SettingsFetched'


  setSettings: ->

    @[key].setDefaultValue value  for own key, value of @settings


  handleSettingsChanged: (key, value) ->

    @appStorage.setValue key, value

    { componentId } = @getOptions()
    appManager      = kd.getSingleton 'appManager'
    appManager.tell 'IDE', 'updateSettings', componentId, key, value
