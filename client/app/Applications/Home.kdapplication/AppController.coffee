class HomeAppController extends AppController

  KD.registerAppClass this,
    name         : "Home"
    route        : "/Home"          # slug removed intentionally
    hiddenHandle : yes
    behavior     : "hideTabs"
    navItem      :
      title      : "Home"
      path       : "/Home"
      order      : 9

  constructor:(options = {}, data)->

    {entryPoint} = KD.config

    Konstructor = if entryPoint and entryPoint.type is 'group' then GroupHomeView else HomeAppView

    options.view    = new Konstructor
      cssClass      : "content-page home"
      domId         : "content-page-home"
      entryPoint    : entryPoint
    options.appInfo =
      name          : "Home"

    super options,data
