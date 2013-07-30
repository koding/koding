class DomainsRoutingView extends JView

  notifyError = (err)->
    new KDNotificationView
      type     : "mini"
      cssClass : "error"
      duration : 5000
      title    : err

  getNoItemView = (partial)-> new KDCustomHTMLView {cssClass : 'no-item', partial}

  constructor:->

    super

    domain = @getData()

    @dropArea = new KDView
      cssClass : 'drop-area'
      bind     : "drop dragenter dragover"
      partial  : "<span class='arrow'></span><cite class='bg-text'>#{domain.domain}</cite>"

    @routingSelector = new KDSelectBox
      name          : 'routing-type'
      selectOptions : [
        { title:"VMs",   value:"VM" }
        { title:"Kites", value:"Kite" }
      ]
      callback      : @bound 'switchRouting'

    @disconnectedVMController = new KDListViewController
      noItemFoundWidget : getNoItemView "You do not have any more VMs to point to <b>#{domain.domain}</b>."
      view              : new KDListView
        cssClass        : 'vm-list'
        itemClass       : DomainVMListItemView
      , domain

    @disconnectedKiteController = new KDListViewController
      noItemFoundWidget : getNoItemView "No Kites available."
      view              : new KDListView
        cssClass        : 'kite-list'
        itemClass       : DomainVMListItemView
      , domain

    @connectedVMController = new KDListViewController
      noItemFoundWidget : getNoItemView "You haven't pointed any VMs to <b>#{domain.domain}</b> yet."
      view              : new KDListView
        cssClass        : 'vm-list'
        itemClass       : DomainVMListItemView
      , domain

    @connectedKiteController = new KDListViewController
      noItemFoundWidget : getNoItemView "No Kites available."
      view              : new KDListView
        cssClass        : 'kite-list'
        itemClass       : DomainVMListItemView
      , domain

    @disconnectedVMs   = @disconnectedVMController.getView()
    @disconnectedKites = @disconnectedKiteController.getView()
    @connectedVMs      = @connectedVMController.getView()
    @connectedKites    = @connectedKiteController.getView()

    @disconnectedKites.hide()
    @connectedKites.hide()

    @dropArea.addSubView @connectedVMs
    @dropArea.addSubView @connectedKites

    connectedVMList    = @connectedVMController.getListView()
    disconnectedVMList = @disconnectedVMController.getListView()

    @disconnectedVMs.addSubView   new KDCustomHTMLView tagName : 'cite', pistachio : "your VMs",   cssClass : "bg-text"
    @disconnectedKites.addSubView new KDCustomHTMLView tagName : 'cite', pistachio : "your Kites", cssClass : "bg-text"

    connectedVMList.on    'VMItemClicked', @bound 'unbindVM'
    disconnectedVMList.on 'VMItemClicked', @bound 'bindVM'

  viewAppended:->
    super
    @fetchVms()
    @resize()

  bindVM:(listItem)->
    domain          = @getData()
    vm              = listItem.getData()
    {hostnameAlias} = vm
    options         = {hostnameAlias}

    if domain.hostnameAlias.length > 0
      listItem.hideLoader()
      return new KDNotificationView
        title : "A domain name can only be bound to one VM."

    domain.bindVM options, (err)=>
      listItem.hideLoader()
      unless err
        @disconnectedVMController.removeItem listItem
        @connectedVMController.addItem vm
        domain.hostnameAlias.push hostnameAlias
      else
        notifyError err.message or err

  unbindVM:(listItem)->
    domain          = @getData()
    vm              = listItem.getData()
    {hostnameAlias} = vm
    options         = {hostnameAlias}

    listItem.showLoader()

    domain.unbindVM options, (err)=>
      listItem.hideLoader()
      unless err
        @connectedVMController.removeItem listItem
        @disconnectedVMController.addItem vm
        domain.hostnameAlias.splice domain.hostnameAlias.indexOf(hostnameAlias), 1
      else
        notifyError err.message or err

  fetchVms:->

    domain = @getData()
    @connectedVMController.showLazyLoader()
    @disconnectedVMController.showLazyLoader()
    KD.remote.api.JVM.fetchVms (err, vms)=>
      if vms
        vmList = ({hostnameAlias:vm} for vm in vms)  if vms.length > 0

        for vm in vmList
          if vm.hostnameAlias in domain.hostnameAlias
            continue if @connectedVMController.itemsIndexed[vm.hostnameAlias]
            @connectedVMController.addItem vm
          else
            continue if @disconnectedVMController.itemsIndexed[vm.hostnameAlias]
            @disconnectedVMController.addItem vm

      @connectedVMController.hideLazyLoader()
      @disconnectedVMController.hideLazyLoader()


  switchRouting:(value)->
    if value is "VM"
      @connectedVMs.show()
      @disconnectedVMs.show()
      @connectedKites.hide()
      @disconnectedKites.hide()
    else
      @connectedVMs.hide()
      @disconnectedVMs.hide()
      @connectedKites.show()
      @disconnectedKites.show()

  pistachio:->
    """
    <header>
    Click on any of your {{> @routingSelector}} to point to <a href='http://#{@getData().domain}' target='_blank'>{{ #(domain)}}</a>
    </header>
    {{> @disconnectedVMs}}
    {{> @disconnectedKites}}
    {{> @dropArea}}
    """

  resize:->
    tabs      = @parent.getDelegate()
    container = tabs.tabHandleContainer
    half = (tabs.getHeight() - container.getHeight() - @$('header').outerHeight(no))/2
    @dropArea.setHeight half
    @disconnectedKites.setHeight half
    @disconnectedVMs.setHeight half