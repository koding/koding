registerAppClass = require '../util/registerAppClass'
mixpanel = require '../util/mixpanel'
kd = require 'kd'
KDController = kd.Controller
HelpModal = require './helpmodal'


module.exports = class HelpController extends KDController

  name    = 'HelpController'
  version = "0.1"

  registerAppClass this, {name, version, background: yes}

  showHelp:(delegate)->
    mixpanel "Help modal show, success"

    @_modal?.destroy?()
    @_modal = new HelpModal {delegate}

    storage = kd.singletons.localStorageController.storage('HelpController')
    storage.setValue 'shown', yes

