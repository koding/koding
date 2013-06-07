class DomainMainView extends KDView

  constructor:(options={}, data)->
    options.cssClass or= "domains"
    data             or= {}

    @domainsListViewController = new DomainsListViewController
      viewOptions:
        cssClass : 'domain-list'

    @buildView()

    super options, data

    @domainsListViewController.on "domainItemClicked", @bound "decorateMapperView"

    """
    @getSingleton("kiteController").run
      vmName: "koding~mengu"
      kiteName: "os"
      method: "exec"
      withArgs: "sed 's/ServerName \(.*\)/ServerName www.mengu.net/g' /etc/apache2/sites-available/"
    , (err, response) ->
      if err then warn err
    """

  buildView:->
    @domainsListView    = @domainsListViewController.getView()
    @domainMapperView   = new DomainMapperView
    @firewallMapperView = new FirewallMapperView

    @addNewDomainButton = new KDButtonView
      title    : 'Add New Domain'
      cssClass : 'editor-button new-domain-button'
      callback : (elm, event) =>
        @domainModalView = new DomainRegisterModalFormView #successCallback: @domainsListViewController.appendNewDomain

    @refreshDomainsButton = new KDButtonView
      title    : 'Refresh Domains'
      cssClass : 'editor-button refresh-domains-button'
      callback : (elm, event)=>
        @domainsListViewController.update()

    @buildTabs()

    @splitView = new KDSplitView
      type      : "vertical"
      resizable : no
      sizes     : ["10%", "90%"]
      views     : [@domainsListView, @tabView]

  buildAccordions:->
    # VM, Kite & Firewall Accordion Groups
    @accordionView = new AccordionView
      activePane : "Virtual Machines"
    @vmsAccPane    = new AccordionPaneView
      title: "Virtual Machines"
    @kitesAccPane  = new AccordionPaneView
      title: "Kites"

    @accordionView.addPanes [@vmsAccPane, @kitesAccPane]

    @vmsAccPane.setContent @domainMapperView
    @kitesAccPane.setContent new KDCustomHTMLView

  buildTabs:->
    # Routing & Analytics Tabs
    @tabView       = new KDTabView
    @routingPane   = new KDTabPaneView
      name     : "Routing"
      closable : no
    @analyticsPane = new KDTabPaneView
      name     : "Analytics"
      closable : no
    @firewallPane  = new KDTabPaneView
      name     : "Firewall"
      closable : no

    
    vmMapperSubView   = @domainMapperView
    kiteMapperSubView = new KDView
      partial: 'Kites are listed here.'
    kiteMapperSubView.hide()

    routingContentView = new KDCustomHTMLView
      partial: "Connect my domain to:"

    routingContentView.addSubView new KDSelectBox
      selectOptions: [{title:"VM", value:"VM"}, {title:"Kite", value:"Kite"}]
      callback: (value)->
        if value is "VM"
          vmMapperSubView.show()
          kiteMapperSubView.hide()
        else
          vmMapperSubView.hide()
          kiteMapperSubView.show()

    @routingPane.addSubView routingContentView
    @routingPane.addSubView vmMapperSubView
    @routingPane.addSubView kiteMapperSubView

    @firewallPane.addSubView @firewallMapperView

    [@routingPane, @analyticsPane, @firewallPane].forEach (pane)=>
      @tabView.addPane pane

    @tabView.showPaneByIndex 0

  viewAppended:->
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    <div class="start-tab app-list-wrapper">
    {{> @addNewDomainButton}}
    {{> @refreshDomainsButton}}
    </div>
    {{> @splitView}}
    """  

  decorateMapperView:(item)->
    @firewallMapperView.getData().domain = item
    @domainMapperView.updateContent item

class DomainMapperView extends KDView

  constructor:(options={}, data)->
    options.partial = '<div>Select a domain to continue.</div>'
    super options, data

  updateContent:(item)->
    data = item.data
    @updatePartial ""
    @destroySubViews()

    @addSubView new KDCustomHTMLView
      partial : """<div class="domain-name">Your domain: <strong>#{data.name}</strong></div>"""

    KD.remote.api.JVM.fetchVms (err, vms)=>
      if vms
        vmList = ({name:vm} for vm in vms)

        @vmListViewController = new VMListViewController
          viewOptions :
            cssClass  : 'vm-list'
        
        @vmListViewController.getListView().setData
          domainName: data.name
          vms       : if data.vms then (vm for vm in data.vms) else []

        @vmListViewController.instantiateListItems vmList
        @addSubView @vmListViewController.getView()
      else
        @addSubView new KDCustomHTMLView
          partial: "<div>You don't have any VMs right now.</div>"



class VMListItemView extends KDListItemView
  constructor:(options={}, data)->
    
    super options, data

    listViewData = @getDelegate().getData()
    switchStatus = if @getData().name in listViewData.vms then on else off

    @onOff = new KDOnOffSwitch
      size        : 'tiny'
      labels      : ['CON', "DCON"]
      defaultValue: switchStatus
      callback : (state) =>
        KD.remote.api.JDomain.bindVM 
          vmName    : @getData().name
          domainName: listViewData.domainName
          state     : state
        , (response) ->
          new KDNotificationView
            type : "top"
            title: response

  viewAppended:->
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    <div style="width: 120px !important;">{{ #(name) }}</div>
    {{> @onOff }}
    """
  

class DomainsListItemView extends KDListItemView

  constructor: (options={}, data)->
    options.cssClass = 'domain-item'
    super options, data

  click: (event)->
    listView = @getDelegate()
    listView.emit "domainsListItemViewClicked", this
    

  viewAppended:->
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    <div>
      <span class="domain-icon link"></span>
      <span class="domain-title">{{ #(name)}}</span>
    </div>
    """



  
  

