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

    KD.remote.api.JVM.fetchVms (err, vms)=>
      if vms

        hostnameAliases = domain.hostnameAlias
        vmList = []
        (vmList.push {hostnameAlias:vm} for vm in vms)  if vms

        @vmListViewController = new VMListViewController
          viewOptions :
            cssClass  : 'vm-list'

        @vmListViewController.getListView().setData
          domain          : domain
          hostnameAliases : if hostnameAliases then (alias for alias in hostnameAliases) else []

        @vmListViewController.instantiateListItems vmList
        @addSubView @vmListViewController.getView()
      else
        @addSubView new KDCustomHTMLView
          partial: "<div>You don't have any VMs right now.</div>"


class DomainVMListItemView extends KDListItemView
  constructor:(options={}, data)->
    options.cssClass = 'domain-vm-item'
    super options, data

    {hostnameAlias} = @getData()
    listViewData    = @getDelegate().getData()
    switchStatus    = hostnameAlias in listViewData.hostnameAliases
    domainInstance  = listViewData.domain

    @onOff = new KDOnOffSwitch
      size        : 'small'
      labels      : ['CONNECTED', "DISCONNECTED"]
      defaultValue: switchStatus
      callback : (state) =>
        domainInstance.bindVM
          hostnameAlias : hostnameAlias
          state         : state
        , (err) =>
          unless err
            notificationMsg = if state
            then "Your domain is connected to the #{hostnameAlias} VM."
            else "Your domain is disconnected from the #{hostnameAlias} VM."
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
    <span class="vm-name">{{ #(hostnameAlias) }}</span>
    {{> @onOff }}
    """