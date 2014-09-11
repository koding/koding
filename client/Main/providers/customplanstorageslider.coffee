class CustomPlanStorageSlider extends KDSliderBarView

  constructor: (options = {}, data)->

    super KD.utils.extend options,
      interval   : 1
      width      : 285
      snap       : yes
      snapOnDrag : yes
      drawBar    : yes
      showLabels : yes # [1, 3, 5, 7, 10, 15, 20, 25, 30]
    , data

  createHandles:->

    super

    handle = @handles.first
    handle.addSubView handleLabel = new KDView
      partial  : "#{handle.value}GB"
      cssClass : "handle-label"

    @on "ValueIsChanging", (val)->
      handleLabel.updatePartial "#{val}GB"
