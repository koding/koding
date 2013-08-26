class DemosMainView extends KDScrollView

  viewAppended:->
    @addSubView new KDSliderBarView
      minValue  : 0
      maxValue  : 100
      step      : 10
      handles   : 
        handle1 : 
          value : 0
        handle2 :
          value : 50