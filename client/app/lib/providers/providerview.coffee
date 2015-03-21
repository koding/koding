kd = require 'kd'
KDView = kd.View
KDTabView = kd.TabView
KDHeaderView = kd.HeaderView
KDModalView = kd.ModalView
KDListViewController = kd.ListViewController
ProviderKoding = require './providerkoding'
ProviderRackspace = require './providerrackspace'
ProviderDigitalOcean = require './providerdigitalocean'
ProviderGoogle = require './providergoogle'
ProviderAmazon = require './provideramazon'
ProviderEngineyard = require './providerengineyard'
ProviderItemView = require './provideritemview'
ProviderWelcomeView = require './providerwelcomeview'
SplitViewWithOlderSiblings = '../commonviews/splitviewwitholdersiblings'

module.exports = class ProviderView extends KDView

  constructor:(options = {}, data)->

    options.cssClass ?= 'provider-base-view'
    super options, data

    @providerController = new KDListViewController
      selection     : yes
      viewOptions   :
        cssClass    : 'provider-list'
        itemClass   : ProviderItemView
    , items         : [
      { name : "Koding",       view : new ProviderKoding }
      { name : "Rackspace",    view : new ProviderRackspace }
      { name : "DigitalOcean", view : new ProviderDigitalOcean }
      { name : "Google",       view : new ProviderGoogle }
      { name : "Amazon",       view : new ProviderAmazon }
      { name : "EngineYard",   view : new ProviderEngineyard }
    ]

  viewAppended:->

    @mainView = new KDTabView
      cssClass : "provider-mainview"
      stack    : @getOption 'stack'
      hideHandleContainer : yes

    @providerListView = new KDView

    @providerListView.addSubView new KDHeaderView
      title : "Providers"
      type  : "medium"

    @providerListView.addSubView @providerController.getView()

    @addSubView @messagesSplit = new SplitViewWithOlderSiblings
      sizes     : ["200px",null]
      views     : [@providerListView, @mainView]
      cssClass  : "provider-split"
      resizable : no

    # Add provider views to mainview
    for provider in @providerController.getListItems()
      @mainView.addPane provider.getData().view, no

    # Add Welcome pane
    @mainView.addPane new ProviderWelcomeView

    @providerController.on "ItemSelectionPerformed", (controller, item)=>
      {view} = item.items.first.getData()
      @mainView.showPane view
