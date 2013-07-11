class DomainsMainView extends JView

  paneData = [
      { name : "Routing" }
      { name : "Analytics",   partial  : "<p class='soon'>Domain analytics will be here soon.</p>" }
      { name : "Firewall",    partial  : "<p class='soon'>Firewall settings will be here soon.</p>" }
      { name : "DNS Manager", partial  : "<p class='soon'>DNS settings will be here soon.</p>" }
    ]

  constructor:(options={}, data)->
    options.cssClass or= "domains"
    data             or= {}

    super options, data

  viewAppended:->

    @domainsListViewController = new DomainsListViewController
      viewOptions:
        tagName  : "ul"
        cssClass : "split-section-list left-section"

    @domainsListView    = @domainsListViewController.getView()

    @buildButtonsBar()

    @tabView = new KDTabView
      cssClass             : "domain-detail-tabs"
      hideHandleCloseIcons : yes
      paneData             : paneData


    @splitView = new SplitViewWithOlderSiblings
      type      : "vertical"
      resizable : no
      sizes     : [ "100%", null ]
      views     : [ @domainsListView, @tabView ]

    super

    @tabView.showPaneByIndex 0

    @getSingleton("mainView").once "transitionend", =>
      @splitView._windowDidResize()

    @domainsListViewController.on "domainItemClicked", @bound "decorateMapperView"


  buildButtonsBar: ->
    @buttonsBar = new KDView cssClass : "header"
    @actionArea = new KDView cssClass : 'action-area'

    @buttonsBar.addSubView @addNewDomainButton = new KDButtonView
      title     : 'Add New Domain'
      cssClass  : 'editor-button new-domain-button left'
      icon      : yes
      iconClass : 'plus'
      callback  : (elm, event) =>
        @actionArea.setClass 'in'
        @buttonsBar.setClass 'out'

    @buttonsBar.addSubView @refreshDomainsButton = new KDButtonView
      style       : "clean-gray"
      icon        : yes
      iconOnly    : yes
      iconClass   : "refresh"
      loader      :
        color     : "#777777"
        diameter  : 24
      tooltip     :
        title     : "Refresh"
        placement : "left"
      callback    : (elm, event)=>
        @domainsListViewController.update()
        @refreshDomainsButton.hideLoader()

    @actionArea.addSubView creationForm = new DomainCreationForm

    creationForm.on 'DomainCreationCancelled', =>
      @actionArea.unsetClass 'in'
      @buttonsBar.unsetClass 'out'

    creationForm.on 'DomainSaved', (domain)=>
      @domainsListViewController.update()
      # fixme: this is to select just saved domain
      # but somehow fails. will check later.
      # @domainsListViewController.update =>
      #   @domainsListViewController.itemsOrdered.forEach (listItem)=>
      #     if listItem.getData().domain is domain.domain
      #       KD.utils.wait 5000, =>
      #         list = @domainsListViewController.getListView()
      #         list.emit "domainsListItemViewClicked", this

    creationForm.on 'CloseClicked', =>
      @actionArea.unsetClass 'in'
      @buttonsBar.unsetClass 'out'


  pistachio:->
    """
    {{> @buttonsBar}}
    {{> @actionArea}}
    {{> @splitView}}
    """

  decorateMapperView:(item)->
    # mapperViews = [@firewallMapperView, @domainMapperView, @dnsManagerView]
    # mapperViews = [@firewallMapperView, @dnsManagerView]

    # for view in mapperViews
    #   view.emit "DomainChanged", item
    domain = item.getData()

    p.destroyMainView() for p in @tabView.panes when p.mainView

    @tabView.getPaneByName('Routing').setMainView     new DomainsRoutingView {}, domain
    @tabView.getPaneByName('Firewall').setMainView    new FirewallMapperView {}, domain
    @tabView.getPaneByName('DNS Manager').setMainView new DNSManagerView     {}, domain

    @splitView.resizePanel "300px", 0, =>
      @tabView.getPaneByName('Routing').getMainView().resize()

