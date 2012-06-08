class KDSliderView extends KDInputView
  constructor:(options)->
    @setType "slider"
    super options
    inputViewOptions = $.extend {type : "hidden"},options
    @addSubView @hiddenInput = new KDInputView inputViewOptions
    @addSubView @sliderHandle = new KDSliderViewHandle()

  setDomElement:(cssClass)->
    @domElement = $ "<div class='kdinput kdinputslider #{cssClass}'></div>"

  setDefaultValue:(value) ->

  getValue:()-> @
  setValue:(value)->

class KDSliderViewHandle extends KDView