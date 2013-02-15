class StartTabAppController extends AppController

  KD.registerAppClass @,
    name     : "StartTab"
    multiple : yes

  constructor:(options = {}, data)->

    options.view = new StartTabMainView

    super options, data

  bringToFront:->

    @emit 'ApplicationWantsToBeShown', @, @getView(),
      hiddenHandle  : no
      type          : 'application'
      name          : 'New Tab'