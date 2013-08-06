class KDLoaderView extends KDView

  constructor:(options, data)->

    o = options or {}
    o.loaderOptions or= {}
    o.size          or= {}
    options =
      tagName       : o.tagName      or "span"
      bind          : o.bind         or "mouseenter mouseleave"
      size          :
        width       : o.size.width  or 12
        height      : o.size.height or 12
      loaderOptions :
        color       : o.loaderOptions.color     or "#000000"   # hex color
        shape       : o.loaderOptions.shape     or "spiral"    # "spiral", "oval", "square", "rect", "roundRect"
        diameter    : o.loaderOptions.diameter  or 12          # 10 - 200
        density     : o.loaderOptions.density   or 30          # 5 - 160
        range       : o.loaderOptions.range     or 0.4         # 0.1 - 2
        speed       : o.loaderOptions.speed     or 1.5         # 1 - 10
        FPS         : o.loaderOptions.FPS       or 24          # 1 - 60

    options.loaderOptions.diameter = options.size.height = options.size.width
    options.cssClass = if o.cssClass then "#{o.cssClass} kdloader" else "kdloader"
    super options, data

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
