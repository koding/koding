kd = require 'kd'
LoginView = require './AppView'

module.exports = class LoginAppsController extends kd.ViewController

  kd.registerAppClass this, { name  : 'Login' }


  constructor: (options = {}, data) ->

    options.view    = new LoginView
      testPath      : 'landing-login'
    options.appInfo =
      name          : 'Login'

    super options, data


  handleQuery: ({ query }) ->

    loginView = @getOption 'view'
    loginView.setCustomData query


  headBannerShowInvitation: (invite) ->

    view = @getView()
    view.headBannerShowInvitation invite


  setStorageData: (key, value) ->

    @appStorage = kd.getSingleton('appStorageController').storage 'Login', '1.0'
    @appStorage.fetchStorage (storage) =>
      @appStorage.setValue key, value, (err) ->
        warn "Failed to set #{key} information"  if err
