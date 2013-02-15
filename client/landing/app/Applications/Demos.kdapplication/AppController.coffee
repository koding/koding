class DemosAppController extends AppController

  KD.registerAppClass @, name : "Demos"

  constructor:(options = {}, data)->
    options.view = new DemosMainView
      cssClass : "content-page demos"

    super options, data

  bringToFront:()->
    super name : 'Demos'#, type : 'background'

  loadView:(mainView)->

    mainView.addSubView input = new KDInputView
      name      : "lol"
      validate  :
        rules   :
          required : yes
        events  :
          required : 'click'
      click     : -> log 'zozo'

    input.on 'click', -> log 'zoma'

    mainView.addSubView button = new KDButtonView
      title    : 'reset validation'
      callback : ->
        input.setValidation
          rules   :
            required : yes
          events  :
            required : 'blur'
