kd = require 'kd'

curryIn = require 'app/util/curryIn'

EnvironmentsModal     = require 'app/environment/environmentsmodal'
SidebarOwnMachineList = require './sidebarownmachineslist'


module.exports = class SidebarStackMachineList extends SidebarOwnMachineList

  constructor: (options = {}, data) ->

    options.title    = options.stack.title

    curryIn options, cssClass: 'stack-machines'

    super

    @bindEvents()


  bindEvents: ->

    { computeController } = kd.singletons

    computeController.checkStackRevisions()

    computeController
      .on 'StackRevisionChecked', @bound 'onStackRevisionChecked'
      .on 'StacksInconsistent',   @bound 'addStackModifiedWarning'


  onStackRevisionChecked: (stack) ->

    return  if @isDestroyed # This needs to be investigated ~ GG
                            # We're creating instances of this multiple times
                            # but somehow we're not cleaning up them correctly

    { _revisionStatus } = stack

    if not _revisionStatus?.error? and { status } = _revisionStatus
      if status?.code > 0
      then @unreadCount.show()
      else @unreadCount.hide()


  createHeader: ->

    super

    @addSubView @warningWrapper = new kd.CustomHTMLView


  addStackModifiedWarning: (stack) ->

    return  if stack.getId() isnt @getOption('stack').getId()
    return  @stackModifiedWarning.show()  if @stackModifiedWarning?

    @stackModifiedWarning = new kd.CustomHTMLView
      cssClass : 'warning-section re-init'
      partial  : "You have different resources in your stack.
                  <span>Click here</span> to re-initialize this stack."
      click    : -> new EnvironmentsModal

    @warningWrapper.addSubView @stackModifiedWarning
