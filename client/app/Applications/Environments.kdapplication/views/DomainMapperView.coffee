class DomainMapperView extends KDView

  constructor:(options={}, data)->
    options.cssClass = 'domain-mapper-view'
    options.partial = '<div>Select a domain to continue.</div>'
    data or= {}
    super options, data

    @on "domainChanged", (domainListItem)->
      @getData().domain = domainListItem.data
      @updateViewContent()

  updateViewContent:->
    domain = @getData().domain
    @updatePartial ""
    @destroySubViews()

    KD.remote.api.JVM.fetchVmsWithHostnames (err, vms)=>
      if vms

        hostnameAliases = domain.hostnameAlias

        @vmListViewController = new VMListViewController
          viewOptions :
            cssClass  : 'vm-list'

        @vmListViewController.getListView().setData
          domain          : domain
          hostnameAliases : if hostnameAliases then (alias for alias in hostnameAliases) else []

        @vmListViewController.instantiateListItems vms
        @addSubView @vmListViewController.getView()
      else
        @addSubView new KDCustomHTMLView
          partial: "<div>You don't have any VMs right now.</div>"


class DomainVMListItemView extends KDListItemView
  constructor:(options={}, data)->
    options.cssClass = 'domain-vm-item'
    super options, data

    listViewData   = @getDelegate().getData()
    switchStatus   = off
    for hostnameAlias in @getData().hostnameAlias
      if hostnameAlias in listViewData.hostnameAliases
        switchStatus = on

    domainInstance = listViewData.domain

    @onOff = new KDOnOffSwitch
      size        : 'small'
      labels      : ['CONNECTED', "DISCONNECTED"]
      defaultValue: switchStatus
      callback : (state) =>
        domainInstance.bindVM
          vmName     : @getData().name
          state      : state
        , (err) =>
          unless err
            {name} = @getData()
            notificationMsg = if state
            then "Your domain is connected to the #{name} VM."
            else "Your domain is disconnected from the #{name} VM."
            new KDNotificationView
              type     : "mini"
              cssClass : "success"
              duration : 5000
              title    : notificationMsg
          else
            new KDNotificationView
              type     : "mini"
              cssClass : "error"
              duration : 5000
              title    : err

  viewAppended:->
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    <span class="vm-icon personal"></span>
    <span class="vm-name">{{ #(name) }}</span>
    {{> @onOff }}
    """