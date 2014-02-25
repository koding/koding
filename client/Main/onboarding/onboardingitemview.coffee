class OnboardingItemView extends JView

  constructor: (options = {}, data) ->

    options.cssClass   = KD.utils.curry "onboarding-item", options.cssClass
    parentOffset       = options.parentElement.getDomElement().offset()
    options.position   =
      top              : parentOffset.top + 40
      left             : parentOffset.left

    super options, data

    {hasPrev, hasNext} = @getOptions()
    @prevButton        = new KDCustomHTMLView
    @nextButton        = new KDCustomHTMLView
    @overlay           = new KDOverlayView
      isRemovable      : no
      parent           : "body"

    if hasPrev
      @prevButton      = new KDButtonView
        cssClass       : "prev-button solid medium light-gray"
        title          : "PREV"
        callback       : => @emit "NavigationRequested", "prev"

    if hasNext
      @nextButton      = new KDButtonView
        cssClass       : "next-button solid medium green"
        title          : "NEXT"
        callback       : => @emit "NavigationRequested", "next"

    @appendToDomBody()

    @on "NavigationRequested", (direction) =>
      @overlay.destroy()
      @destroy()
      @getDelegate().emit "NavigationRequested", direction, @getData()

  pistachio: ->
    {title, content} = @getData().partial
    """
      <h3>#{title}</h3>
      <p>#{content}</p>
      <div class="buttons">
        {{> @prevButton}}
        {{> @nextButton}}
      </div>
    """
