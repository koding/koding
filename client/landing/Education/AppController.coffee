class EducationAppController extends AppController

  KD.registerAppClass this,
    name         : "Education"
    route        : "/Education"
    preCondition :
      condition  : (options, cb)-> cb !KD.isLoggedIn()
      failure    : (options, cb)-> KD.singletons.router.handleRoute '/Activity'

  constructor:(options = {}, data)->

    options.view    = new EducationView
      cssClass      : "content-page education"

    super options, data
