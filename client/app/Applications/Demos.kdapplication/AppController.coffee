class DemosAppController extends AppController
  constructor:(options = {}, data)->
    options.view = new DemosMainView
      cssClass : "content-page demos"

    super options, data

  bringToFront:()->
    super name : 'Demos'#, type : 'background'

  loadView:(mainView)->