class KDLoaderView extends KDView
  constructor:(options = {},data)->
    options = $.extend
      tagName       : "span"
      cssClass      : ""
      bind          : "mouseenter mouseleave"
      size          :
        width       : 12
        height      : 12
      loaderOptions :
        color       : "#000000"   # hex color
        shape       : "spiral"    # "spiral", "oval", "square", "rect", "roundRect"
        diameter    : 12          # 10 - 200
        density     : 30          # 5 - 160
        range       : 0.4         # 0.1 - 2
        speed       : 1.5         # 1 - 10
        FPS         : 24          # 1 - 60
    ,options
    options.loaderOptions.diameter = options.size.height = options.size.width
    options.cssClass += "kdloader" 
    super options,data
  
  viewAppended:->
    @canvas = new CanvasLoader @getElement(), id : "cl_#{@id}"
    {loaderOptions} = @getOptions()
    for option,value of loaderOptions
      @canvas["set#{option.capitalize()}"] value

  show:->
    super
    @active = yes
    @canvas.show() if @canvas
  
  hide:->
    super
    @active = no
    @canvas.hide() if @canvas
  
  # easter
  mouseEnter:->
    @canvas.setColor @utils.getRandomHex()
    @canvas.setSpeed 1

  mouseLeave:->
    @canvas.setColor @getOptions().loaderOptions.color
    @canvas.setSpeed @getOptions().loaderOptions.speed
  
  mouseMove:->
    @canvas.setColor @utils.getRandomHex()
