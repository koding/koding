class EnvironmentsMainView extends JView

  viewAppended:->

    @addSubView new HeaderViewSection type : "big", title : "Environments"
    @addSubView new EnvironmentsMainScene
