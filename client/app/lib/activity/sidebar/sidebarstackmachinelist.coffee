kd = require 'kd'

curryIn = require 'app/util/curryIn'

SidebarOwnMachineList = require './sidebarownmachineslist'


module.exports = class SidebarStackMachineList extends SidebarOwnMachineList

  constructor: (options = {}, data) ->

    options.title    = options.stack.title

    curryIn options, cssClass: 'stack-machines'

    super

    @bindEvents()


  bindEvents: ->

    { computeController } = kd.singletons

    computeController.on 'StackRevisionChecked', @bound 'onStackRevisionChecked'


  onStackRevisionChecked: (stack) ->

    return  if @isDestroyed # This needs to be investigated ~ GG
                            # We're creating instances of this multiple times
                            # but somehow we're not cleaning up them correctly

    { _revisionStatus } = stack

    if not _revisionStatus?.error? and { status } = _revisionStatus
      @unreadCount.show()  if status?.code > 0
