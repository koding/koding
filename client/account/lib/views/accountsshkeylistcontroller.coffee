$ = require 'jquery'
kd = require 'kd'
KDButtonView = kd.ButtonView
AccountListViewController = require '../controllers/accountlistviewcontroller'
remote = require('app/remote').getInstance()


module.exports = class AccountSshKeyListController extends AccountListViewController
  constructor:(options,data)->

    options.noItemFoundText = "You have no SSH key."
    super options,data

    @loadItems()

    @getListView().on "UpdatedItems", =>
      @newItem = no
      newKeys = @getListItems().map (item)-> item.getData()
      unless newKeys.length is 0 then @customItem?.destroy()
      remote.api.JUser.setSSHKeys newKeys, -> kd.log "Saved keys."

    @getListView().on "RemoveItem", (item)=>
      @newItem = no
      @removeItem item
      @getListView().emit "UpdatedItems"

    @newItem = no

  loadItems: ()->
    @removeAllItems()
    @showLazyLoader no

    remote.api.JUser.getSSHKeys (keys)=>
      @instantiateListItems keys
      @hideLazyLoader()

      @addButton?.destroy()

      @addButton = new KDButtonView
        cssClass  : 'add-big-btn'
        title     : 'Add new SSH key'
        icon      : yes
        callback  : =>
          unless @newItem
            @newItem = true
            @addItem {key: '', title: ''}, 0
            @getListView().items.first.swapSwappable hideDelete: yes

      @getListView().addSubView @addButton, '', yes

