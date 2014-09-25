class AddWorkspaceView extends KDCustomHTMLView

  constructor: (options = {}, data) ->

    options.cssClass = 'add-workpace-view'

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
        KD.utils.stopDOMEvent event
        return no

      data           = @getData()
      options        =
        name         : @input.getValue()
        machineUId   : data.machineUId
        machineLabel : data.machineLabel

      {activitySidebar}  = KD.getSingleton 'mainView'
      @hasPendingRequest = yes

      activitySidebar.createNewWorkspace options

      activitySidebar.once 'WorkspaceCreated', =>
        KD.utils.defer => @hasPendingRequest = no
