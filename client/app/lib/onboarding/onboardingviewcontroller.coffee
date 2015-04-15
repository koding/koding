kd = require 'kd'
KDViewController = kd.ViewController
OnboardingItemView = require './onboardingitemview'


module.exports = class OnboardingViewController extends KDViewController

  constructor: (options = {}, data) ->

    super options, data

    {@groupName, @slug} = @getOptions()
    {@items}            = @getData()

    @show @items.first


  show: (item) ->

    view = new OnboardingItemView { @slug, @groupName, @items }, item
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


