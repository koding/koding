_                                = require 'lodash'
kd                               = require 'kd'
nick                             = require 'app/util/nick'
remote                           = require('app/remote').getInstance()
KDView                           = kd.View
Machine                          = require 'app/providers/machine'
isKoding                         = require 'app/util/isKoding'
UserItem                         = require 'app/useritem'
KDCustomHTMLView                 = kd.CustomHTMLView
ComputeErrorUsageModal           = require './computeerrorusagemodal'
KDAutoCompleteController         = kd.AutoCompleteController
MachineSettingsCommonView        = require './machinesettingscommonview'
ActivityAutoCompleteUserItemView = require 'app/activity/activityautocompleteuseritemview'
Tracker                          = require 'app/util/tracker'


module.exports = class MachineSettingsVMSharingView extends MachineSettingsCommonView


  constructor: (options = {}, data) ->

    options.headerTitle          = 'Shared With'
    options.addButtonTitle       = 'INVITE'
    options.headerAddButtonTitle = 'ADD SOMEONE'
    options.listViewItemClass    = UserItem
    options.loaderOnHeaderButton = yes
    options.listViewItemOptions  = { justFirstName: no, size: { width: 32, height: 32 } }
    options.noItemFoundWidget    = new KDCustomHTMLView
      cssClass : 'no-item'
      partial  : 'This VM has not yet been shared with anyone.'
    options.listViewOptions      =
      fetcherMethod              : (query, options, callback) =>
        options = _.extend options, { permanentOnly: yes }
        @machine.jMachine.reviveUsers options, (err, users = [])  -> callback err, users

    @machine = data

    super options, data

    @_users  = []

    @listController.getListView().on 'KickUserRequested', @bound 'kickUser'

    kd.singletons.notificationController.on 'MachineShareListUpdated', @bound 'initList'


  initList: ->

    return no  if @getData().status.state isnt Machine.State.Running

    @machine.jMachine.reviveUsers { permanentOnly: yes }, (err, users = []) =>

      kd.warn err  if err

      @updateInMemoryListOfUsers users
      @listController.lazyLoader.hide()
      @listController.replaceAllItems users

      if @listController.getItemCount() is 0
        @listController.noItemView.show()


  updateInMemoryListOfUsers: (users) ->

    # For blacklisting the users in auto complete fetcher
    users  ?= (item.getData() for item in @listController.getListItems())
    @_users = [nick()].concat (user.profile.nickname for user in users)


  addUser: (user) ->

    Tracker.track Tracker.VM_SHARED
    @modifyUsers user, 'add'


  kickUser: (userItem) ->

    userItem.setLoadingMode yes
    Tracker.track Tracker.VM_KICKED_SHARED
    @modifyUsers userItem.getData(), 'kick', userItem


  modifyUsers: (user, task, userItem) ->

    { profile: { nickname } } = user

    remote.api.SharedMachine[task] @machine.uid, [nickname], (err) =>

      return @showNotification err  if err

      kite   = @machine.getBaseKite()
      method = if task is 'add' then 'klientShare' else 'klientUnshare'

      kite[method] { username: nickname, permanent: yes }

        .then => @initList()

        .catch (err) =>
          errorMessages = [
            'user is already in the shared list.'
            'user is not in the shared list.'
          ]

          if err.message in errorMessages
          then @initList()
          else @showNotification err

          userItem.setLoadingMode yes


  createAddInput: ->

    @autoComplete = new KDAutoCompleteController
      name                : 'userController'
      placeholder         : 'Type a username...'
      itemDataPath        : 'profile.nickname'
      listWrapperCssClass : 'private-message vm-sharing hidden'
      itemClass           : ActivityAutoCompleteUserItemView
      outputWrapper       : new KDView { cssClass: 'hidden' }
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


  fetchAccounts: ({ inputValue }, callback) ->

    kd.singletons.search.searchAccounts inputValue
      .filter (it) => it.profile.nickname not in @_users
      .then callback
      .timeout 1e4
      .catch (err) ->
        console.warn 'Error while autoComplete: ', err
        callback []


  showAddView: ->

    return super  unless isKoding()

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
