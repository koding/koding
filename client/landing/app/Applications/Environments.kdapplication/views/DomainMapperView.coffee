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

    @addSubView new KDCustomHTMLView
      partial : """<div class="domain-name">Your domain: <strong>#{domain.domain}</strong></div>"""

    KD.remote.api.JVM.fetchVmsWithHostnames (err, vms)=>
      if vms

        @vmListViewController = new VMListViewController
          viewOptions :
            cssClass  : 'vm-list'
        
        @vmListViewController.getListView().setData
          domainName      : domain.domain
          hostnameAliases : if domain.hostnameAlias then (hostnameAlias for hostnameAlias in domain.hostnameAlias) else []

        @vmListViewController.instantiateListItems vms
        @addSubView @vmListViewController.getView()
      else
        @addSubView new KDCustomHTMLView
          partial: "<div>You don't have any VMs right now.</div>"


class DomainVMListItemView extends KDListItemView
  constructor:(options={}, data)->
    options.cssClass = 'domain-vm-item'
    super options, data

    listViewData = @getDelegate().getData()
    switchStatus = if @getData().hostnameAlias in listViewData.hostnameAliases then on else off

    @onOff = new KDOnOffSwitch
      size        : 'small'
      labels      : ['CON', "DCON"]
      defaultValue: switchStatus
      callback : (state) =>
        KD.remote.api.JDomain.bindVM 
          vmName    : @getData().name
          domainName: listViewData.domainName
          state     : state
        , (response) ->
          new KDNotificationView
            type : "top"
            title: response

  viewAppended:->
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    <span class="vm-icon personal"></span>
    <span class="vm-name">{{ #(name) }}</span>
    {{> @onOff }}
    """