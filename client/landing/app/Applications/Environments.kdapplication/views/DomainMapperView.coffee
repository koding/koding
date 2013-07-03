class DomainMapperView extends KDView

  constructor:(options={}, data={})->

    options.cssClass = 'domain-mapper-view'
    options.partial  = '<div>Select a domain to continue.</div>'

    super options, data

  viewAppended:->
    domain = @getData()
    @updatePartial ""
    @destroySubViews()

    KD.remote.api.JVM.fetchVmsWithHostnames (err, vms)=>
      if vms
        @vmListViewController = new KDListViewController
          view        : new KDListView
            cssClass  : 'vm-list'
            itemClass : DomainVMListItemView
          , domain
        ,
          items       : vms
        @addSubView @vmListViewController.getView()
      else
        @addSubView new KDCustomHTMLView
          partial: "<div>You don't have any VMs right now.</div>"
