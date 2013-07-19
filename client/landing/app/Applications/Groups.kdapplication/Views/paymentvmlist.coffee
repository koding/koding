class GroupVMsModal extends KDModalViewWithForms

  constructor:(options, data)->
    {group} = options

    options =
      title                   : "User VMs"
      content                 : ''
      overlay                 : yes
      width                   : 500
      height                  : "auto"
      cssClass                : ""
      tabs                    :
        navigable             : yes
        goToNextFormOnSubmit  : no
        forms                 :
          history             :
            fields            :
              Instances       :
                type          : 'hidden'
                cssClass      : 'database-list'
            buttons           :
              Refresh         :
                style         : "modal-clean-gray"
                type          : 'submit'
                loader        :
                  color       : "#444444"
                  diameter    : 12
                callback      : =>
                  form = @modalTabs.forms.history
                  @dbController.loadItems =>
                    form.buttons.Refresh.hideLoader()

    super options, data

    @dbController = new GroupVMsListController
      group     : group
      itemClass : GroupVMsListItem

    dbList = @dbController.getListView()

    dbListForm = @modalTabs.forms.history
    dbListForm.fields.Instances.addSubView @dbController.getView()

    @dbController.loadItems()

class GroupVMsListController extends KDListViewController

  constructor:(options = {}, data)->
    @group = options.group
    super

  loadItems:(callback)->
    @removeAllItems()
    @customItem?.destroy()
    @showLazyLoader no

    items = []
    @group.getAllExpenses {}, (err, vms) =>
      if err or vms.length is 0
        @addCustomItem "There are no user VMs."
        @hideLazyLoader()
      else
        for v in vms
          items.push
            name : v.hostnameAlias
        @instantiateListItems items
        @hideLazyLoader()
      callback?()

  addCustomItem:(message)->
    @removeAllItems()
    @customItem?.destroy()
    @scrollView.addSubView @customItem = new KDCustomHTMLView
      cssClass : "no-item-found"
      partial  : message


class GroupVMsListItem extends KDListItemView
  constructor:(options,data)->
    super options,data

  viewAppended:->
    super

  partial:(data)->
    """
      #{data.name}
    """