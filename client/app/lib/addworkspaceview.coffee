kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
KDInputView = kd.InputView
IDEHelpers = require 'ide/idehelpers'


module.exports = class AddWorkspaceView extends KDCustomHTMLView

  constructor: (options = {}, data) ->

    options.cssClass = 'add-workspace-view kdlistitemview-main-nav workspace'

    super options, data

    @addSubView new KDCustomHTMLView tagName: 'figure'

    @addSubView @input  = new KDInputView
      type     : 'text'
      keydown  : @bound 'handleKeyDown'

    @addSubView @cancel = new KDCustomHTMLView
      cssClass : 'cancel'
      click    : @bound 'destroy'

    @once 'WorkspaceCreated',      @bound 'clearFlag'
    @once 'WorkspaceCreateFailed', @bound 'clearFlag'


  click: -> return no


  handleKeyDown: (event) ->

    if event.which is 13

      if @hasPendingRequest
        kd.utils.stopDOMEvent event
        return no

      data           = @getData()
      options        =
        name         : @input.getValue()
        machineUId   : data.machineUId
        machineLabel : data.machineLabel
        eventObj     : this # dirty vibe!

      IDEHelpers.createWorkspace options
      @hasPendingRequest = yes


  clearFlag: -> kd.utils.defer => @hasPendingRequest = no
