requirejs.config baseUrl: "/a/js", waitSeconds:30

class IDEAppController extends AppController

  KD.registerAppClass this,
    name         : "IDE"
    route        : "/:name?/IDE"
    behavior     : "application"
    preCondition :
      condition  : (options, cb)-> cb KD.isLoggedIn()
      failure    : (options, cb)->
        KD.singletons.appManager.open 'IDE', conditionPassed : yes
        KD.showEnforceLoginModal()

  constructor: (options = {}, data) ->
    options.appInfo =
      type          : "application"
      name          : "IDE"

    super options, data

    layoutOptions       =
      direction         : "vertical"
      splitName         : "BaseSplit"
      sizes             : [ null, "250px" ]
      views             : [
        {
          type          : "split"
          options       :
            direction   : "vertical"
            sizes       : [ "250px", null]
            colored     : yes
          views         : [
            {
              type      : "custom"
              paneClass : IDEFilesTabView
            },
            {
              type      : "custom"
              paneClass : IDEEditorTabView
            }
          ]
        },
        {
          type          : "custom"
          paneClass     : IDESocialsTabView
        }
      ]

    workspace = new Workspace { layoutOptions }
    workspace.once "ready", => @getView().addSubView workspace.getView()
