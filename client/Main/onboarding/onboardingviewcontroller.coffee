class OnboardingViewController extends KDViewController

  constructor: (options = {}, data) ->

    super options, data

    {@app}   = @getOptions()
    {@items} = @getData()

    @show @items.first
    @on "NavigationRequested", (direction, itemData) =>
      @navigate direction, itemData

  navigate: (direction, itemData) ->
    index = @items.indexOf itemData
    item  = if direction is "next" then @items[++index] else @items[--index]
    @show item

  show: (item) ->
    new OnboardingItemView { delegate: this, @app, @items }, item
