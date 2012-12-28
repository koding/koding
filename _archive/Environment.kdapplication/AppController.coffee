class Environment12345 extends AppController
  constructor:()->
    mainViewClass = PageEnvironment
    @mainView = new mainViewClass
      cssClass : "content-page"
    super

  bringToFront:()->
    super name : 'Environment'
