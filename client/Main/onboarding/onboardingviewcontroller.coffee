class OnboardingViewController extends KDViewController

  constructor: (options = {}, data) ->

    super options, data

    {@app, @slug} = @getOptions()
    {@items}      = @getData()

    @show @items.first, yes

  show: (item, setStorage) ->
    view = new OnboardingItemView { @slug, @app, @items, setStorage }, item
    @bindViewEvents view

  navigate: (direction, itemData) ->
    index = @items.indexOf itemData
    item  = if direction is "next" then @items[++index] else @items[--index]
    @show item

  bindViewEvents: (view) =>
    view.on "NavigationRequested", (direction) =>
      @navigate direction, view.getData()

    view.on "OnboardingShown", (slug) =>
      @getDelegate().emit "OnboardingShown", slug
