kd                        = require 'kd'
KDView                    = kd.View
MachineSettingsCommonView = require './machinesettingscommonview'

module.exports = class MachineSettingsVMSharingView extends MachineSettingsCommonView


  constructor: (options = {}, data) ->

    options.headerTitle          = 'Shared With'
    options.addButtonTitle       = 'INVITE'
    options.headerAddButtonTitle = 'ADD PEOPLE'
    # options.listViewItemClass    =

    super options, data
