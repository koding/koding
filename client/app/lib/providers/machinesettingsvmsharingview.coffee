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
