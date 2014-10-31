class SingleActivityPane extends ActivityPane

  viewAppended:->

    @setClass 'single-activity'
    @tabView.hideHandleContainer()
    @addSubView @tabView

