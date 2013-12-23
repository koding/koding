class DevToolsMainView extends JView

  constructor:->
    super

    KD.singletons.appManager.require 'Ace', =>
      @addSubView @view = new AceAppView