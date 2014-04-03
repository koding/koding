class EducationAppController extends AppController

  KD.registerAppClass this,
    name         : "Education"
    route        : "/Education"

  constructor:(options = {}, data)->

    options.view    = new EducationView
      cssClass      : "content-page education"

    super options, data
