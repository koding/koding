class OnboardingItemView extends JView

  constructor: (options = {}, data) ->

    options.cssClass   = KD.utils.curry "onboarding-item", options.cssClass

    super options, data

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
