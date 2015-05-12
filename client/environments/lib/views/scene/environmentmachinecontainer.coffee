ComputeHelpers         = require 'app/providers/computehelpers'
EnvironmentContainer   = require './environmentcontainer'
EnvironmentMachineItem = require './environmentmachineitem'


module.exports = class EnvironmentMachineContainer extends EnvironmentContainer

  constructor: (options={}, data) ->

    options      =
      title      : 'virtual machines'
      cssClass   : 'machines'
      itemClass  : EnvironmentMachineItem
      itemHeight : 55

    super options, data

    @on 'PlusButtonClicked', =>
      ComputeHelpers.handleNewMachineRequest stack: @getData()
