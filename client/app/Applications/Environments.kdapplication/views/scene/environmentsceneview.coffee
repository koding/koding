class EnvironmentScene extends KDDiaScene

  constructor:->
    super
      cssClass  : 'environments-scene'
      lineWidth : 1

  whenItemsLoadedFor:do->
    # poor man's when/promise implementation ~ GG
    (containers, callback)->
      counter = containers.length
      containers.forEach (container)->
        container.once "DataLoaded", ->
          if counter is 1 then do callback
          counter--

  viewAppended:->
    super

    @addSubView slider = new KDSliderBarView
      cssClass   : 'zoom-slider'
      minValue   : 30
      maxValue   : 100
      interval   : 10
      width      : 120
      snap       : no
      snapOnDrag : no
      drawBar    : yes
      showLabels : no
      handles    : [100]

    slider.on 'ValueChanged', (value)=>
      do _.throttle =>
        @setScale (Math.floor value) / 100