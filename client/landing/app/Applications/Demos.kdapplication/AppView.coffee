class DemosMainView extends KDScrollView

  viewAppended:->
    @addSubView example = new KDSliderBarView
      cssClass   : 'my-cute-slider'
      minValue   : 0
      maxValue   : 100
      interval   : 10
      width 	 : 500
      snap 	     : yes
      drawBar 	 : yes
      showLabels : [0, 25, 50, 75, 100]
      handles    : [60]

