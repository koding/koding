class DNSManagerView extends KDView

  constructor:(options={}, data)->
    data or= {}
    super options, data

    @on "DomainChanged", (domainListItem)->
      @getData().domain = domainListItem.data
      @updateViewContent()

  updateViewContent:->
    {domain} = @getData()

    @destroySubViews()

    @newRecordForm = new NewDNSRecordFormView {}, {domain}
    @recordsListController = new DNSRecordListController {}, {domain}

    @newRecordForm.on "newRecordCreated", (recordObj)=>
      @recordsListController.emit "newRecordCreated", recordObj

    @addSubView @newRecordForm
    @addSubView @recordsListController.getView()


