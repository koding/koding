kd = require 'kd'
KDView = kd.View
KDListViewController = kd.ListViewController
KDAutoCompleteController = kd.AutoCompleteController
ActivityAutoCompleteUserItemView = require 'activity/views/activityautocompleteuseritemview'
UserItem = require './useritem'
nick = require 'app/util/nick'


module.exports = class ManageSharedView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'users-view', options.cssClass

    super options, data

    {@machine} = @getOptions()

    @_users = []

    @autoComplete = new KDAutoCompleteController
      name                : 'userController'
      placeholder         : 'Type a username...'
      itemClass           : ActivityAutoCompleteUserItemView
      itemDataPath        : 'profile.nickname'
      outputWrapper       : new KDView cssClass: 'hidden'
      listWrapperCssClass : 'private-message hidden'
      submitValuesAsText  : yes
      dataSource          : @bound 'fetchAccounts'

    @addSubView @inputView = @autoComplete.getView()
    @inputView.setClass 'input-view'

    @autoComplete.on 'ItemListChanged', (count) =>

      user = @autoComplete.getSelectedItemData()?.last

      if user?
        @addUser user
        @toggleInput yes

        @autoComplete.selectedItemCounter = 0
        @autoComplete.selectedItemData    = []


    @usersController    = new KDListViewController
      viewOptions       :
        type            : 'user'
        wrapper         : yes
        itemClass       : UserItem
        itemOptions     :
          machineId     : @machine._id

    @addSubView @userListView = @usersController.getView()
    @inputView.hide()

    @usersController.getListView()
      .on 'KickUserRequested', @bound 'kickUser'

    @addSubView @loader = new KDLoaderView
      cssClass          : 'in-progress'
      size              :
        width           : 14
        height          : 14
      loaderOptions     :
        color           : '#333333'
      showLoader        : yes

    @addSubView @warning = new KDCustomHTMLView
      cssClass          : 'warning hidden'
      click             : -> @hide()

    @listUsers()


  listUsers: ->

    @loader.show()

    @machine.jMachine.reviveUsers permanentOnly: yes, (err, users)=>
      warn err  if err?

      users  ?= []
      @updateInMemoryListOfUsers users

      @usersController.replaceAllItems users
      @userListView[if users.length > 0 then 'show' else 'hide']()

      @loader.hide()


  modifyUsers: (user, task, userItem)->

    @loader.show()
    @warning.hide()

    {profile:{nickname}} = user

    updateUserList = =>

      if @usersController.getItemCount() > 1

        if task is 'add'
        then @usersController.addItem user
        else @usersController.removeItem userItem

        @updateInMemoryListOfUsers()

      else

        @listUsers()


    @machine.jMachine.shareWith
      target    : [nickname]
      permanent : yes
      asUser    : task is 'add'

    , (err)=>

      return @showError err  if err

      kite   = @machine.getBaseKite()
      method = if task is 'add' then 'klientShare' else 'klientUnshare'

      kite[method] { username: nickname, permanent: yes }

        .then -> updateUserList()

        .catch (err)=>
          if err.message in ['user is already in the shared list.'
                             'user is not in the shared list.']
          then updateUserList()
          else @showError err

        .finally => @loader.hide()


  addUser: (user)->
    @modifyUsers user, 'add'


  kickUser: (userItem)->
    @modifyUsers userItem.getData(), 'kick', userItem


  updateInMemoryListOfUsers: (users)->

    # For blacklisting the users in auto complete fetcher
    users  ?= (item.getData() for item in @usersController.getListItems())
    @_users = [nick()].concat (user.profile.nickname for user in users)


  toggleInput: (informOthers = no)->

    @inputView.toggleClass 'hidden'

    {windowController} = kd.singletons

    windowController.addLayer @inputView
    @inputView.setFocus()

    @emit "UserInputCancelled"  if informOthers
    @inputView.off  "ReceivedClickElsewhere"
    @inputView.once "ReceivedClickElsewhere", (event)=>
      return  if $(event.target).hasClass 'toggle'
      @emit "UserInputCancelled"
      @inputView.hide()
      @warning.hide()


  fetchAccounts: ({inputValue}, callback) ->

    kd.singletons.search.searchAccounts inputValue
      .filter (it) => it.profile.nickname not in @_users
      .then callback
      .timeout 1e4
      .catch Promise.TimeoutError, callback.bind this, []


  showError: (err)->

    @warning.setTooltip title: err.message
    @warning.show()
    @loader.hide()
