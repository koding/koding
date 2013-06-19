class ViewerAppController extends KDViewController

  KD.registerAppClass this,
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
          ////home/(.*)/Web/(.*)///, "http://$1.#{KD.config.userSitesDomain}/$2"
        cb publicPath isnt path, {path: publicPath}

      failure    : (options, cb)->
        correctPath = \
          "/home/#{KD.nick()}/Web/"
        KD.getSingleton("appManager").notify "File must be under: #{correctPath}"

  constructor:(options = {}, data)->

    options.view = new PreviewerView
      params     : options.params

    options.appInfo =
      title         : "Preview"
      cssClass      : "ace"

    super options, data

  open:(path)->
    @getView().openPath path