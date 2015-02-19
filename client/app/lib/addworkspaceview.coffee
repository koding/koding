kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
KDInputView = kd.InputView
module.exports = class AddWorkspaceView extends KDCustomHTMLView

  constructor: (options = {}, data) ->

    options.cssClass = 'add-workspace-view'

    super options, data

    @addSubView new KDCustomHTMLView tagName: 'figure'

    @addSubView @input  = new KDInputView
      type     : 'text'
      keydown  : @bound 'handleKeyDown'

    @addSubView @cancel = new KDCustomHTMLView
      cssClass : 'cancel'
      click    : @bound 'destroy'


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

      {activitySidebar}  = kd.getSingleton 'mainView'
      @hasPendingRequest = yes

      activitySidebar.createNewWorkspace options

      activitySidebar.once 'WorkspaceCreated', @bound 'clearFlag'

      activitySidebar.once 'WorkspaceCreateFailed', @bound 'clearFlag'


  clearFlag: ->
    kd.utils.defer => @hasPendingRequest = no


