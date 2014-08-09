class InitializeMachineView extends KDView

  constructor:->

    super cssClass : 'init-machine-view'


  viewAppended:->

    # @addSubView new KDCustomHTMLView
    #   partial  : "This machine is not initialized, do you want to do it now?"

    @addSubView new KDButtonView
      title    : "Initialize"
      cssClass : "solid green mini"
      callback : @lazyBound "emit", "Initialize"
