# FIXME - Move this in a seperate file ~ GG

class VmListItem extends KDListItemView

  click: ->
    @getDelegate().emit 'VMSelected', @getData()

  viewAppended: ->
    JView::viewAppended.call this

  pistachio: ->
    """
      <div class="vm-info">
        <cite></cite>
        #{@getData().hostnameAlias}
      </div>
    """

class VMSelection extends KDModalView

  constructor:(options={}, data)->

    super
      width           : 300
      title           : "Select a VM"
      overlay         : yes
      # cssClass        : KD.utils.curry 'vm-selection', options.cssClass
      draggable       : no
      cancellable     : yes
      appendToDomBody : yes
      delegate        : options.delegate
    , data

    @listController   = new KDListViewController
      view            : new KDListView
        type          : "vm"
        cssClass      : "vm-list"
        itemClass     : VmListItem

  viewAppended:->
    # @unsetClass 'kdmodal'
    @addSubView view = @listController.getView()

    @listController.getListView().on 'VMSelected', (vm)=>
      @emit "VMSelected", vm
      @destroy()

    @listController.instantiateListItems KD.getSingleton('vmController').vms
