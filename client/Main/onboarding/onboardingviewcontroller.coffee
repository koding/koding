class OnboardingViewController extends KDController

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
    path     = @escapePath item.partial.path
    appName  = @app.getOptions().name
    itemName = item.name
    hasNext  = @items.indexOf(item) isnt @items.length - 1
    hasPrev  = @items.indexOf(item) isnt 0

    try
      parentElement = eval path
      if parentElement instanceof KDView
        delegate = this
        view     = new OnboardingItemView { delegate, parentElement, @app, hasNext, hasPrev }, item
      else
        details  = { appName: appName, itemName: itemName }
        console.warn "Parent element is not a KDView instance", details
    catch e
      details = { appName: appName, itemName: itemName, error: e }
      console.warn "Path parse error for onboarding item", details

  escapePath: (path) ->
    escaped  = path.replace(/\[/g, ".").replace(/\]/g, ".")
    splitted = escaped.split "."
    result   = splitted.first

    for item, index in splitted when item
      result += """["#{item}"]"""  if index > 0

    return result
