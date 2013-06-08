class DomainMainView extends KDView

  constructor:(options={}, data)->
    options.cssClass or= "domains"
    data             or= {}

    @domainMapperView = new DomainMapperView

    @domainsListViewController = new DomainsListViewController
      viewOptions:
        cssClass : 'domain-list'
      
    @domainsListView = @domainsListViewController.getView()

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

    @splitView = new KDSplitView
      type      : "vertical"
      resizable : no
      sizes     : ["10%", "90%"]
      views     : [@domainsListView, @domainMapperView]

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

    @vmListView = new KDListItemView
    @vmListController = new KDListViewController
      itemClass: @vmListItemView

    KD.remote.api.JVM.fetchVms (err, vms)=>
      if vms
        vms.forEach (vm)=>
          @addSubView new KDCustomHTMLView
            partial: "<div>#{vm}</div>"
      else
        @addSubView new KDCustomHTMLView
          partial: "<div>You don't have any VMs right now.</div>"


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