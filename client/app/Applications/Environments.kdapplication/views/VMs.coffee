class VMMainView extends JView

  constructor:(options={}, data)->

    options.cssClass or= "vms"
    data or= {}
    super options, data

    @vmListController = new KDListViewController
      startWithLazyLoader : no
      viewOptions         :
        type              : "vm-list"
        cssClass          : "vm-list"
        itemClass         : VMListItemView

    @vmListView = @vmListController.getView()
    @vmListView.on "Clicked", (data)->
      @getVMInfo data.name

    @splitView = new KDSplitView
      type      : 'vertical'
      resizable : no
      sizes     : ['30%', null]
      views     : [@vmListView, null]

    @loadItems()

  getVMInfo:(vmName, callback)->
    kc = KD.singletons.kiteController
    kc.run
      kiteName: 'os',
      vmName: vmName,
      method: 'vm.info'
    , callback

  loadItems:->
    @vmListController.removeAllItems()
    @vmListController.showLazyLoader no

    KD.remote.api.JVM.fetchVms (err, vms)=>
      if err
        @vmListController.hideLazyLoader()
      else
        stack = []
        vms.forEach (name)=>
          stack.push (cb)=>

            @getVMInfo name, (err, info)->
              if err or info.state != 'RUNNING'
                status = 'off'
              else
                status = 'on'

              cb null, {
                name   : name
                group  : 'Koding'
                domain : 'bahadir.kd.io'
                type   : 'personal'
                status : status
              }

        async.parallel stack, (err, results)=>
          @vmListController.hideLazyLoader()
          unless err
            @vmListController.instantiateListItems results

  pistachio:->
    """
      {{> @splitView}}
    """

class VMListItemView extends KDListItemView
  constructor: (options, data) ->
    options.cssClass or= "vm-item"
    options.click = @bound "clicked"
    super options, data

  clicked: (event)->
    @getDelegate().emit "Clicked", @getData()

  partial: ->
    data = @getData()
    """
    <div>
      <span class="vm-icon #{data.type}"></span>
      <span class="vm-status #{data.status}"></span>
      <span class="vm-title">
        #{data.name} - #{data.group}
      </span>
      <span class="vm-domain">http://#{data.domain}</span>
    </div>
    """