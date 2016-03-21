kd                        = require 'kd'
nick                      = require 'app/util/nick'
remote                    = require('app/remote').getInstance()
SshKey                    = require 'app/util/sshkey'
Machine                   = require 'app/providers/machine'
KDModalView               = kd.ModalView
KDButtonView              = kd.ButtonView
KDHeaderView              = kd.HeaderView
KDCustomHTMLView          = kd.CustomHTMLView
KodingListController      = require 'app/kodinglist/kodinglistcontroller'
AccountNewSshKeyView      = require './accountnewsshkeyview'
environmentDataProvider   = require 'app/userenvironmentdataprovider'


module.exports = class AccountSshKeyListController extends KodingListController

  constructor: (options = {}, data) ->

    options.noItemFoundText   = 'You have no SSH key.'
    options.fetcherMethod     = (query, options, callback) ->
      remote.api.JUser.getSSHKeys (keys) -> callback null, keys

    super options, data


  bindEvents: ->

    super

    listView = @getListView()

    listView.on 'ItemAction', ({ action, item }) =>
      switch action
        when 'UpdatedItems'
          @saveItems()
        when 'RemoveItem'
          @deleteItem item
        when 'NewItemSubmitted'
          @submitNewItem item
        when 'EditItem'
          @editItem item
        when 'CancelItem'
          @cancelItem item


    listView.on 'ItemWasRemoved', (item) =>
      kd.utils.defer => @showNoItemWidget()

    @once 'FetchProcessSucceeded', (keys) =>

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
    newKeys = @getListItems().map (item) -> item.getData()
    @updateHelpLink newKeys
    remote.api.JUser.setSSHKeys newKeys, -> kd.log 'Saved keys.'


  deleteItem: (item) ->

    isNew = item instanceof AccountNewSshKeyView

    @cancelItem item
    @removeItem item

    # If item is new, just remove it from DOM
    # It doesn't have data in DB, so there is no need to update items
    return  if isNew

    @saveItems()
    @showDeleteModal()


  showDeleteModal: ->

    nickname = nick()
    modal    = new KDModalView
      title          : 'Deleting SSH Key'
      content        : """
        <p>
          Please note that even though the SSH key has been deleted from Account Settings,
          it still exists in your <strong>/home/#{nickname}/.ssh/authorized_keys</strong> file.
          Please ensure that you delete the key from that file too.
          <a href="https://koding.com/docs/ssh-into-your-vm/#deleting-a-key" target="_blank" class="guide-link">This guide</a> shows how to delete a ssh key.
        </p>
      """
      overlay        : yes
      overlayOptions :
        cssClass     : 'delete-ssh-key-overlay'
      cssClass       : 'delete-ssh-key-modal'
      buttons        :
        ok           :
          cssClass   : 'solid green medium'
          title      : 'OK'
          callback   : -> modal.destroy()


  submitNewItem: (item) ->

    { key, title, machines } = item.getData()

    sk = new SshKey { key }
    sk.deployTo machines, (err) =>
      if err
        item.emit 'SubmitFailed', err
      else
        @addItem { key, title }
        @deleteItem item
        @saveItems()


  editItem: (item) ->

    @currentItem?.cancelItem yes
    @currentItem = item
    listItem.hide() for listItem in @getListItems() when listItem isnt item
    @sshKeyHelpLink?.hide()


  cancelItem: (item) ->

    @currentItem = null
    listItem.show() for listItem in @getListItems() when listItem isnt item
    @sshKeyHelpLink?.show()


  # Override parent method and use it for different thing.
  removeItem: (item) ->

    @getListView().removeItem item


  showNewItemForm: ->

    return  if @currentItem instanceof AccountNewSshKeyView

    { ViewType } = AccountNewSshKeyView
    type         = ViewType.NoMachines
    machines     = environmentDataProvider.getMyMachines().map (node) ->
      new Machine { machine : node.machine }

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
    return  unless keys.length > 0

    @sshKeyHelpLink = new KDCustomHTMLView
      cssClass : 'ssh-key-help'
      partial  : '''
        <a href="https://koding.com/docs/ssh-into-your-vm/#deleting-a-key" target="_blank">How to delete ssh key from your VM</a>
      '''
    @getListView().addSubView @sshKeyHelpLink


  isMachineActive: (machine) ->

    { status: { state } } = machine
    return state is Machine.State.Running
