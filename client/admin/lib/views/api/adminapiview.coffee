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

    @createSwitch()
    @createTabView()


  createSwitch: ->

    @addSubView @settingsView = new kd.CustomHTMLView
      partial: 'Enable API Access'
      cssClass: 'settings-row'

    @settingsView.addSubView @apiSwitch = new KodingSwitch
      callback      : (state) ->
        getGroup().modify { isApiEnabled : state }, (err) ->
          showError err  if err


  createTabView: ->

    data    = @getData()
    tabView = new kd.TabView hideHandleCloseIcons: yes

    tabView.tabHandleContainer.addSubView new kd.ButtonView
      cssClass : 'solid compact green add-new'
      title    : 'Add new API Token'
      callback : =>
        remote.api.JApiToken.create (err, apiToken) =>
          return showError err  if err
          kd.utils.defer =>
            @apiTokenListView.listController.addItem apiToken

    tabView.addPane apiTokens = new kd.TabPaneView name: 'Api Tokens'

    apiTokens.addSubView @apiTokenListView = new APITokenListView
      noItemFoundWidget : new kd.CustomHTMLView
        partial         : 'No api token found!'
        cssClass        : 'no-item-view'
    , data

    tabView.showPaneByIndex 0
    @addSubView tabView


  viewAppended: ->

    super
    status = getGroup().isApiEnabled is yes
    @apiSwitch.setDefaultValue status


