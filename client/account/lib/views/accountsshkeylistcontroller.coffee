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

    @getListView().on "UpdatedItems", =>
      @newItem = no
      newKeys = @getListItems().map (item)-> item.getData()
      unless newKeys.length is 0 then @customItem?.destroy()
      @updateHelpLink newKeys
      remote.api.JUser.setSSHKeys newKeys, -> kd.log "Saved keys."

    @getListView().on "RemoveItem", (item)=>
      @newItem = no
      @removeItem item
      @getListView().emit "UpdatedItems"

    @getListView().on "NewKeySubmitted", (item)=>
      @newItem = no
      { key, title, machines } = item.getData()

      sk = new SshKey { key }
      sk.deploy machines, (err) =>
        if err
          item.emit "KeyFailed", err
        else
          @removeItem item
          @addItem { key, title }
          @getListView().emit "UpdatedItems"

    @newItem = no

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
        callback  : @bound 'addNewKey'

      @getListView().addSubView @header, '', yes

      @updateHelpLink keys


  addNewKey: ->

    unless @newItem
      @newItem = yes
      { computeController } = kd.singletons
      computeController.fetchMachines (err, machines) =>
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
    if keys.length > 0
      @sshKeyHelpLink = new KDCustomHTMLView
        cssClass : 'ssh-key-help'
        partial  : """
          <a href="http://learn.koding.com/guides/ssh-into-your-vm/#deleting-a-key" target="_blank">How to delete ssh key from your VM</a>
        """
      @getListView().addSubView @sshKeyHelpLink


  isMachineActive: (machine) ->

    { status: { state } } = machine
    return state is Machine.State.Running