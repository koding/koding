class DomainsRoutingView extends JView

  notifyError = (err)->
    new KDNotificationView
      type     : "mini"
      cssClass : "error"
      duration : 5000
      title    : err

  constructor:->

    super

    domain = @getData()

    @dropArea = new KDView
      cssClass : 'drop-area'
      bind     : "drop dragenter dragover"
      partial  : "<span class='arrow'></span><cite>#{domain.domain}</domain>"

    @routingSelector = new KDSelectBox
      name          : 'routing-type'
      selectOptions : [
        { title:"VMs",   value:"VM" }
        { title:"Kites", value:"Kite" }
      ]
      callback      : @bound 'switchRouting'

    @disconnectedVMController = new KDListViewController
      view        : new KDListView
        cssClass  : 'vm-list'
        itemClass : DomainVMListItemView
      , domain

    @disconnectedKiteController = new KDListViewController
      view        : new KDListView
        cssClass  : 'kite-list'
        itemClass : DomainVMListItemView
      , domain

    @connectedVMController = new KDListViewController
      view        : new KDListView
        cssClass  : 'vm-list'
        itemClass : DomainVMListItemView
      , domain

    @connectedKiteController = new KDListViewController
      view        : new KDListView
        cssClass  : 'kite-list'
        itemClass : DomainVMListItemView
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
      else
        @connectedVMController.showNoItemWidget()
        @disconnectedVMController.showNoItemWidget()

      @connectedVMController.hideLazyLoader()
      @disconnectedVMController.hideLazyLoader()
      # @connectedVMController.showNoItemWidget()
      # @disconnectedVMController.showNoItemWidget()


  switchRouting:(value)->
    if value is "VM"
      @connectedVMs.show()
      @disconnectedVMs.show()
      @disconnectedKites.hide()
      @connectedKites.hide()
    else
      @connectedVMs.hide()
      @disconnectedVMs.hide()
      @disconnectedKites.show()
      @connectedKites.show()

  pistachio:->
    """
    <header>
    Click on any of your {{> @routingSelector}} to point and load balance to <a href='#{@getData().domain}' target='_blank'>{{ #(domain)}}</a>
    </header>
    {{> @disconnectedVMs}}
    {{> @disconnectedKites}}
    {{> @dropArea}}
    """
    # {{> @vmMapperView}}
    # {{> @kiteMapperView}}

  resize:->
    tabs      = @parent.getDelegate()
    container = tabs.tabHandleContainer
    half = (tabs.getHeight() - container.getHeight() - @$('header').outerHeight(no))/2
    @dropArea.setHeight half
    @disconnectedKites.setHeight half
    @disconnectedVMs.setHeight half