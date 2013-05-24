class ViewerAppController extends KDViewController

  KD.registerAppClass @,
    name         : "Viewer"
    route        : "/Develop"
    multiple     : yes
    openWith     : "forceNew"
    behavior     : "application"
    preCondition :

      condition  : (options, cb)->
        {path, vmName} = options
        return cb true  unless path
        path = FSHelper.plainPath path
        publicPath = path.replace \
          ///.*\/(.*\.#{KD.config.userSitesDomain})\/(.*)///, '//$1/$2'

        cb publicPath isnt path, {path: publicPath}

      failure    : (options, cb)->
        correctPath = \
          "/home/#{KD.nick()}/Sites/#{KD.nick()}.#{KD.config.userSitesDomain}/"
        appManager.notify "File must be under: #{correctPath}"

  constructor:(options = {}, data)->

    options.view = new PreviewerView
      params     : options.params

    options.appInfo =
      title         : "Preview"
      cssClass      : "ace"

    super options, data

  open:(path)->
    @getView().openPath path


  openFile: (nodeView) ->
    # TODO: Need to handle file types such as images.
    @getView().openPath nodeView.path