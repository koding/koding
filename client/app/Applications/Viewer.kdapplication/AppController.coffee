class ViewerAppController extends KDViewController

  KD.registerAppClass @,
    name         : "Viewer"
    route        : "Develop"
    multiple     : yes
    openWith     : "forceNew"
    behavior     : "application"

  constructor:(options = {}, data)->

    options.view    = new PreviewerView
    options.appInfo =
      title        : "Preview"
      cssClass     : "ace"

    super options, data

  open:(path)->

    @getView().openPath path