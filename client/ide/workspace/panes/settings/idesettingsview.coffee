EditorSettingsView = require './editorsettingsview'


class IDESettingsView extends JView

  constructor: (options = {}, data) ->

    super options, data

    @unsetClass 'kdview'

    {name, version} = @getStorageInformation()
    controller      = KD.getSingleton 'appStorageController'
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

    appManager = KD.getSingleton 'appManager'
    component  = if this instanceof EditorSettingsView then 'editor' else 'terminal'

    appManager.tell 'IDE', 'updateSettings', component, key, value


module.exports = IDESettingsView
