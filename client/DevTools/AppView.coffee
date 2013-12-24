class DevToolsMainView extends KDView

  viewAppended:->
    KD.singletons.appManager.require 'Ace', =>
      @addSubView @view = new AceAppView