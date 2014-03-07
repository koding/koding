class DomainsMainView extends JView

  paneData = [
      { name : "Routing",     partial  : "<p class='soon'>Select a domain from left to see its settings.</p>"}
      { name : "Analytics",   partial  : "<p class='soon'>Domain analytics will be here soon.</p>" }
      { name : "Firewall",    partial  : "<p class='soon'>Firewall settings will be here soon.</p>" }
      { name : "DNS Manager", partial  : "<p class='soon'>Select a domain from left to see its settings.</p>" }
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
      sizes     : [ "300px", null ]
      views     : [ @domainsListView, @tabView ]

    super

    @tabView.showPaneByIndex 0
    @domainsListViewController.on "domainItemClicked", @bound "decorateMapperView"

    @utils.defer => @splitView._windowDidResize()

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
        @emit 'DomainNameShouldFocus'

    @buttonsBar.addSubView @refreshDomainsButton = new KDButtonView
      style       : "clean-gray"
      icon        : yes
      iconOnly    : yes
      iconClass   : "refresh"
      loader      :
        color     : "#444444"
      tooltip     :
        title     : "Refresh"
        placement : "left"
      callback    : (elm, event)=>
        @domainsListViewController.update()
        @refreshDomainsButton.hideLoader()

    @actionArea.addSubView creationForm = new DomainCreateForm

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

    @on 'DomainNameShouldFocus', ->
      form         = creationForm.forms["Domain Address"]
      {domainName} = form.inputs
      domainName.setFocus()

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

    for p in @tabView.panes when p.mainView
      p.destroyMainView()

    routingPane = @tabView.getPaneByName('Routing')
    firewallPane = @tabView.getPaneByName('Firewall')
    dnsPane = @tabView.getPaneByName('DNS Manager')
    unless item
      routingPane.updatePartial "<p class='soon'>Select a domain from left to see its settings.</p>"
      return

    domain = item.getData()

    routingPane.updatePartial ""
    firewallPane.updatePartial ""
    dnsPane.updatePartial ""

    @tabView.getPaneByName('Routing').setMainView     new DomainsRoutingView {}, domain
    @tabView.getPaneByName('Firewall').setMainView    new FirewallMapperView {}, domain
    @tabView.getPaneByName('DNS Manager').setMainView new DNSManagerView     {}, domain

