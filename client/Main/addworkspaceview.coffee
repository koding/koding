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


  handleKeyDown: (event) ->

    if event.which is 13
      data           = @getData()
      options        =
        name         : @input.getValue()
        machineUId   : data.machineUId
        machineLabel : data.machineLabel

      {activitySidebar} = KD.getSingleton 'mainView'

      activitySidebar.createNewWorkspace options
