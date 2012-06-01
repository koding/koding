class KDSliderView extends KDInputView
  constructor:(options)->
    @inputSetType "slider"
    super options
    inputViewOptions = $.extend {type : "hidden"},options
    @addSubView @hiddenInput = new KDInputView inputViewOptions
    @addSubView @sliderHandle = new KDSliderViewHandle()

  setDomElement:(cssClass)->
    @domElement = $ "<div class='kdinput kdinputslider #{cssClass}'></div>"

  inputSetDefaultValue:(value) ->

  inputGetValue:()-> @
  inputSetValue:(value)->

class KDSliderViewHandle extends KDView