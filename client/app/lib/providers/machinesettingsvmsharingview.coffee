kd                        = require 'kd'
nick                      = require 'app/util/nick'
KDView                    = kd.View
UserItem                  = require 'app/useritem'
MachineSettingsCommonView = require './machinesettingscommonview'


module.exports = class MachineSettingsVMSharingView extends MachineSettingsCommonView


  constructor: (options = {}, data) ->

    options.headerTitle          = 'Shared With'
    options.addButtonTitle       = 'INVITE'
    options.headerAddButtonTitle = 'ADD PEOPLE'
    options.listViewItemClass    = UserItem
    options.listViewItemOptions  = { justFirstName: no, size: width: 32, height: 32 }

    @machine = data

    super options, data

    @listController.getListView().on 'KickUserRequested', @bound 'kickUser'


  initList: ->

    @machine.jMachine.reviveUsers permanentOnly: yes, (err, users = []) =>

      kd.warn err  if err

      @updateInMemoryListOfUsers users
      @listController.lazyLoader.hide()
      @listController.replaceAllItems users


  updateInMemoryListOfUsers: (users) ->

    # For blacklisting the users in auto complete fetcher
    users  ?= (item.getData() for item in @listController.getListItems())
    @_users = [nick()].concat (user.profile.nickname for user in users)


  kickUser: (userItem) ->

    userItem.setLoadingMode yes
    @modifyUsers userItem.getData(), 'kick', userItem


  updateUserList: (task, user, userItem) ->

    return @initList()  unless @listController.getItemCount() > 1

    if task is 'add'
    then @listController.addItem user
    else @listController.removeItem userItem

    @updateInMemoryListOfUsers()


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
