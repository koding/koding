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

    @splitView = new KDSplitView
      type      : 'vertical'
      resizable : no
      sizes     : ['30%', null]
      views     : [@vmListView, null]

    @loadItems()

  loadItems:->
    @vmListController.removeAllItems()
    @vmListController.showLazyLoader no

    KD.remote.api.JVM.fetchVms (err, vms)=>
      if err
        @vmListController.hideLazyLoader()
      else
        stack = []
        vms.forEach (name)->
          stack.push (cb)->
            setTimeout ->
              cb null, {
                name   : name
                group  : 'Koding'
                domain : 'bahadir.kd.io'
              }
            , 3 * 1000

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
    super options, data

  partial: =>
    data = @getData()
    """
    <div>
      <span class="vm-icon personal"></span>
      <span class="vm-title">
        #{data.name} - #{data.group}
      </span>
      <span class="vm-domain">http://#{data.domain}</span>
    </div>
    """