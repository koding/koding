kd                               = require 'kd'
nick                             = require 'app/util/nick'
KDView                           = kd.View
Machine                          = require 'app/providers/machine'
UserItem                         = require 'app/useritem'
KDCustomHTMLView                 = kd.CustomHTMLView
ComputeErrorUsageModal           = require './computeerrorusagemodal'
KDAutoCompleteController         = kd.AutoCompleteController
MachineSettingsCommonView        = require './machinesettingscommonview'
ActivityAutoCompleteUserItemView = require 'activity/views/activityautocompleteuseritemview'


module.exports = class MachineSettingsVMSharingView extends MachineSettingsCommonView


  constructor: (options = {}, data) ->

    options.headerTitle          = 'Shared With'
    options.addButtonTitle       = 'INVITE'
    options.headerAddButtonTitle = 'ADD SOMEONE'
    options.listViewItemClass    = UserItem
    options.loaderOnHeaderButton = yes
    options.listViewItemOptions  = { justFirstName: no, size: width: 32, height: 32 }
    options.noItemFoundWidget    = new KDCustomHTMLView
      cssClass : 'no-item'
      partial  : 'This VM has not yet been shared with anyone.'

    @machine = data

    super options, data

    @_users  = []

    @listController.getListView().on 'KickUserRequested', @bound 'kickUser'


  initList: ->

    return no  if @getData().status.state isnt Machine.State.Running

    @machine.jMachine.reviveUsers permanentOnly: yes, (err, users = []) =>

      kd.warn err  if err

      @updateInMemoryListOfUsers users
      @listController.lazyLoader.hide()
      @listController.replaceAllItems users


  updateInMemoryListOfUsers: (users) ->

    # For blacklisting the users in auto complete fetcher
    users  ?= (item.getData() for item in @listController.getListItems())
    @_users = [nick()].concat (user.profile.nickname for user in users)


  addUser: (user) ->

    @modifyUsers user, 'add'


  kickUser: (userItem) ->

    userItem.setLoadingMode yes
    @modifyUsers userItem.getData(), 'kick', userItem


  updateUserList: (task, user, userItem) ->

    if task is 'add'
    then @listController.addItem user
    else @listController.removeItem userItem

    @updateInMemoryListOfUsers()
    userItem?.setLoadingMode no

    if @listController.getItemCount() is 0
      @listController.noItemView.show()


  modifyUsers: (user, task, userItem) ->

    {profile: {nickname} } = user

    @machine.jMachine.shareWith
      target    : [nickname]
      permanent : yes
      asUser    : task is 'add'

    , (err) =>

      return @showNotification err  if err

      kite   = @machine.getBaseKite()
      method = if task is 'add' then 'klientShare' else 'klientUnshare'

      kite[method] { username: nickname, permanent: yes }

        .then => @updateUserList task, user, userItem

        .catch (err) =>
          errorMessages = [
            'user is already in the shared list.'
            'user is not in the shared list.'
          ]

          if err.message in errorMessages
          then @updateUserList task, user, userItem
          else @showNotification err

          userItem.setLoadingMode yes


  createAddInput: ->

    @autoComplete = new KDAutoCompleteController
      name                : 'userController'
      placeholder         : 'Type a username...'
      itemDataPath        : 'profile.nickname'
      listWrapperCssClass : 'private-message vm-sharing hidden'
      itemClass           : ActivityAutoCompleteUserItemView
      outputWrapper       : new KDView cssClass: 'hidden'
      submitValuesAsText  : yes
      dataSource          : @bound 'fetchAccounts'

    @addViewContainer.addSubView @addInputView = @autoComplete.getView()

    @addInputView.on 'keydown', (e) => @hideAddView()  if e.which is 27

    @autoComplete.on 'ItemListChanged', (count) =>
      user = @autoComplete.getSelectedItemData()?.last

      return unless user

      @addUser user

      @autoComplete.selectedItemCounter = 0
      @autoComplete.selectedItemData    = []



  fetchAccounts: ({inputValue}, callback) ->

    kd.singletons.search.searchAccounts inputValue
      .filter (it) => it.profile.nickname not in @_users
      .then callback
      .timeout 1e4
      .catch (err) ->
        console.warn "Error while autoComplete: ", err
        callback []


  showAddView: ->

    @headerAddNewButton.showLoader()

    kd.singletons.computeController.fetchUserPlan (plan) =>

      @headerAddNewButton.hideLoader()

      if plan is 'free'

        new ComputeErrorUsageModal
          plan    : 'free'
          message : 'VM share feature is only available for paid accounts.'

        return @emit 'ModalDestroyRequested'

      super


  # override parent method
  createAddNewViewButtons: ->
