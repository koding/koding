class OnboardingViewController extends KDViewController

  constructor: (options = {}, data) ->

    super options, data

    {@app, @slug} = @getOptions()
    {@items}      = @getData()

    @show @items.first, yes
    @on "NavigationRequested", (direction, itemData) =>
      @navigate direction, itemData

  show: (item, setStorage) ->
    delegate = this
    new OnboardingItemView { delegate, @slug, @app, @items, setStorage }, item

  navigate: (direction, itemData) ->
    index = @items.indexOf itemData
    item  = if direction is "next" then @items[++index] else @items[--index]
    @show item
