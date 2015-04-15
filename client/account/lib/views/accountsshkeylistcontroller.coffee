$ = require 'jquery'
kd = require 'kd'
KDButtonView = kd.ButtonView
KDCustomHTMLView = kd.CustomHTMLView
AccountListViewController = require '../controllers/accountlistviewcontroller'
AccountNewSshKeyView = require './accountnewsshkeyview'
remote = require('app/remote').getInstance()
KDHeaderView = kd.HeaderView
showError = require 'app/util/showError'
Machine = require 'app/providers/machine'
SshKey = require 'app/util/sshkey'


module.exports = class AccountSshKeyListController extends AccountListViewController

  constructor:(options,data)->

    options.noItemFoundText = "You have no SSH key."
    super options,data

    @loadItems()

    listView = @getListView()
    listView.on "UpdatedItems",     @bound 'saveItems'
    listView.on "RemoveItem",       @bound 'deleteItem'
    listView.on "NewItemSubmitted", @bound 'submitNewItem'
    listView.on "EditItem",         @bound 'editItem'
    listView.on "CancelItem",       @bound 'cancelItem'


  loadItems: ()->

    @removeAllItems()
    @showLazyLoader no

    remote.api.JUser.getSSHKeys (keys)=>
      @instantiateListItems keys
      @hideLazyLoader()

      @header?.destroy()

      @header = new KDHeaderView
        title : 'SSH Keys'

      @header.addSubView new KDButtonView
        title     : 'ADD NEW KEY'
        style     : 'solid green small'
        icon      : yes
        callback  : @bound 'showNewItemForm'

      @getListView().addSubView @header, '', yes

      @updateHelpLink keys


  saveItems: ->

    @currentItem = null
    newKeys = @getListItems().map (item)-> item.getData()
    @updateHelpLink newKeys
    remote.api.JUser.setSSHKeys newKeys, -> kd.log "Saved keys."


  deleteItem: (item) ->

    @cancelItem item
    @removeItem item
    @saveItems()


  submitNewItem: (item) ->

    { key, title, machines } = item.getData()

    sk = new SshKey { key }
    sk.deployTo machines, (err) =>
      if err
        item.emit "SubmitFailed", err
      else
        @addItem { key, title }
        @deleteItem item


  editItem: (item) ->

    @currentItem?.cancelItem yes
    @currentItem = item
    listItem.hide() for listItem in @getListItems() when listItem isnt item
    @sshKeyHelpLink?.hide()


  cancelItem: (item) ->

    @currentItem = null
    listItem.show() for listItem in @getListItems() when listItem isnt item
    @sshKeyHelpLink?.show()


  showNewItemForm: ->

    return  if @isFetchingMachines or @currentItem instanceof AccountNewSshKeyView

    @isFetchingMachines = yes
    { computeController } = kd.singletons
    computeController.fetchMachines (err, machines) =>
      @isFetchingMachines = no
      return showError err  if err

      { ViewType } = AccountNewSshKeyView
      type = ViewType.NoMachines
      if machines.length is 1 and @isMachineActive machines.first
        type = ViewType.SingleMachine
      else if machines.length > 1
        for machine in machines when @isMachineActive machine
          type = ViewType.ManyMachines
          break

      newSshKey = new AccountNewSshKeyView {
        delegate : @getListView()
        type
      },
      { machines }

      @getListView().addItemView newSshKey, 0


  updateHelpLink: (keys) ->

    @sshKeyHelpLink?.destroy()

    @sshKeyHelpLink = new KDCustomHTMLView
      cssClass : 'ssh-key-help'
      partial  : """
        <a href="http://learn.koding.com/guides/ssh-into-your-vm/#deleting-a-key" target="_blank">How to delete ssh key from your VM</a>
      """
    @getListView().addSubView @sshKeyHelpLink


  isMachineActive: (machine) ->

    { status: { state } } = machine
    return state is Machine.State.Running