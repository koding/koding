class DNSManagerView extends KDView

  constructor:(options={}, data)->
    data or= {}
    super options, data

    @on "domainChanged", (domainListItem)->
      @getData().domain = domainListItem.data
      @updateViewContent()

  updateViewContent:->
    {domain} = @getData()

    @destroySubViews()

    @newRecordForm = new NewDNSRecordFormView {}, {domain}
    @recordsListController = new DNSRecordListController {}, {domain}

    @addSubView @newRecordForm
    @addSubView @recordsListController.getView()


