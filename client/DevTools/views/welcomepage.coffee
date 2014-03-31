class DevToolsWelcomePage extends JView

  constructor:(options = {}, data)->

    options.cssClass = KD.utils.curry 'welcome-pane', options.cssClass
    super options, data

    @buttons = new KDView
      cssClass : 'button-container'

    delegate = @getDelegate()
    @addButton title : "Create New", delegate.bound 'createNewApp'

  addButton:({title, type}, callback)->

    type ?= ""
    cssClass = "solid big #{type}"

    @buttons.addSubView new KDButtonView {
      title, cssClass, callback
    }

  pistachio:->
    """
      <h1>Welcome to Koding DevTools</h1>
      {{> @buttons}}
    """

  click:-> @setClass 'in'
