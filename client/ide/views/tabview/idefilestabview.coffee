class IDEFilesTabView extends WorkspaceTabView

  constructor: (options = {}, data) ->

    options.addPlusHandle = no

    super options, data

    tabPane    = new KDTabPaneView
      name     : 'Files'
      closable : no

    tabPane.addSubView new FinderPane
    @tabView.addPane tabPane
