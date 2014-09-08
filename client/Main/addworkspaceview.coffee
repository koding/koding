class AddWorkspaceView extends KDCustomHTMLView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass = 'add-workpace-view'

    super options, data

    @input     = new KDInputView
      type     : 'text'
      keydown  : @bound 'handleKeyDown'

    @cancel    = new KDCustomHTMLView
      cssClass : 'cancel'
      click    : @bound 'destroy'


  handleKeyDown: (event) ->
    if event.which is 13
      options      =
        name       : @input.getValue()
        machineUId : @getData().machineUId

      {activitySidebar} = KD.getSingleton 'mainView'

      activitySidebar.createNewWorkspace options


  pistachio: ->
    """
      <figure></figure>
      {{> @input}}
      {{> @cancel}}
    """