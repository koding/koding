kd               = require 'kd'
remote           = require('app/remote').getInstance()
getGroup         = require 'app/util/getGroup'
showError        = require 'app/util/showError'
KodingSwitch     = require 'app/commonviews/kodingswitch'
APITokenListView = require './apitokenlistview'


module.exports = class AdminAPIView extends kd.View

  constructor: (options = {}, data) ->

    options.cssClass = 'member-related apitokens'

    super options, data

    @initialAPIAccessState = getGroup().isApiEnabled is yes
    @createSwitch()
    @createTabView()


  createSwitch: ->

    @addSubView settingsView = new kd.CustomHTMLView
      partial: 'Enable API Access'
      cssClass: 'settings-row'

    settingsView.addSubView apiSwitch = new KodingSwitch
      callback : (state) =>
        getGroup().modify { isApiEnabled : state }, (err) =>
          if err
            showError err
            # revert switch state in case of error
            if state
            then apiSwitch.setOff no
            else apiSwitch.setOn no

          else
            toggleButtonState @addNewButton, state

    apiSwitch.setDefaultValue @initialAPIAccessState


  createTabView: ->

    data    = @getData()
    tabView = new kd.TabView hideHandleCloseIcons: yes

    @addNewButton = tabView.tabHandleContainer.addSubView new kd.ButtonView
      cssClass : 'solid compact green add-new'
      title    : 'Add new API Token'
      callback : =>
        remote.api.JApiToken.create (err, apiToken) =>
          return showError err  if err
          kd.utils.defer =>
            @apiTokenListView.listController.addItem apiToken

    toggleButtonState @addNewButton, @initialAPIAccessState

    tabView.addPane apiTokens = new kd.TabPaneView name: 'API Tokens'

    apiTokens.addSubView @apiTokenListView = new APITokenListView
      noItemFoundWidget : new kd.CustomHTMLView
        partial         : 'No API token found!'
        cssClass        : 'no-item-view'
    , data

    tabView.showPaneByIndex 0
    @addSubView tabView


toggleButtonState = (button, state) ->

  if state
  then button.enable()
  else button.disable()
