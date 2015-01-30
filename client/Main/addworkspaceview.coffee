class AddWorkspaceView extends KDCustomHTMLView

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
        KD.utils.stopDOMEvent event
        return no

      data           = @getData()
      options        =
        name         : @input.getValue()
        machineUId   : data.machineUId
        machineLabel : data.machineLabel
        eventObj     : this # dirty vibe!

      IDE.helpers.createWorkspace options
      @hasPendingRequest = yes


  clearFlag: -> KD.utils.defer => @hasPendingRequest = no
