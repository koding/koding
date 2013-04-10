class DemosAppController extends AppController

  KD.registerAppClass @,
    name         : "Demos"
    route        : "Demos"
    hiddenHandle : yes

  constructor:(options = {}, data)->
    options.view    = new DemosMainView
      cssClass      : "content-page demos"
    options.appInfo =
      name          : "Demos"

    super options, data

  loadView:(mainView)->

    mainView.addSubView a = new KDView
      partial    : "<span></span>"
      tooltip    :
        title    : "zulaku bereke"
        selector : 'span'


    a.$().css
      display          : "block"
      width            : "50%"
      height           : "50%"
      backgroundColor  : "pink"
      margin           : "100px auto"

    a.$('span').css
      display          : "block"
      width            : "50%"
      height           : "50%"
      backgroundColor  : "blue"
      margin           : "100px auto"