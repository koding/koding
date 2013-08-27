class DemosMainView extends KDScrollView

  viewAppended:->
    @addSubView new KDSliderBarView
      minValue  : 40
      maxValue  : 100
      interval  : 20
    , handles   : 
        handle1 : 
          value : 40