class SingleActivityPane extends ActivityPane

  viewAppended:->

    @tabView.hideHandleContainer()
    @addSubView @tabView

