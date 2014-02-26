class OnboardingItemView extends JView

  constructor: (options = {}, data) ->

    options.cssClass   = KD.utils.curry "onboarding-item", options.cssClass

    super options, data

    @createElements()
    @listenEvents()

  createElements: ->
    {hasPrev, hasNext, isLast} = @getOptions()
    @prevButton    = new KDCustomHTMLView
    @nextButton    = new KDCustomHTMLView
    @doneButton    = new KDCustomHTMLView
    @overlay       = new KDOverlayView
      isRemovable  : no
      parent       : "body"

    if hasPrev
      @prevButton  = new KDButtonView
        cssClass   : "solid medium light-gray"
        title      : "PREV"
        callback   : => @emit "NavigationRequested", "prev"

    if hasNext
      @nextButton  = new KDButtonView
        cssClass   : "solid medium green"
        title      : "NEXT"
        callback   : => @emit "NavigationRequested", "next"

    if isLast
      @doneButton  = new KDButtonView
        cssClass   : "solid medium green"
        title      : "DONE"
        callback   : => @emit "OnboardingCompleted"

  listenEvents: ->
    @on "NavigationRequested", (direction) =>
      @overlay.destroy()
      @destroy()
      @getDelegate().emit "NavigationRequested", direction, @getData()

    @on "OnboardingCompleted", =>
      @overlay.destroy()
      @destroy()
      @getDelegate().emit "OnboardingCompleted"

  pistachio: ->
    {title, content} = @getData()
    """
      <h3>#{title}</h3>
      <p>#{content}</p>
      <div class="buttons">
        {{> @prevButton}}
        {{> @nextButton}}
        {{> @doneButton}}
      </div>
    """
