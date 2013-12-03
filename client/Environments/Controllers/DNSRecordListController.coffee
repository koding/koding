class DNSRecordListController extends KDListViewController

  constructor:(options={}, data)->
    options.itemClass   or= DNSRecordListItemView
    options.noItemFoundWidget  or= new EmptyDNSRecordListItemView
    options.viewOptions or=
      type      : 'env-list'
      tagName   : 'ul'
      partial   :
        """
        <h3 class="records-title clearfix">
          <div class="record-type record-element">Record Type</div>
          <div class="record-host record-element">Host</div>
          <div class="record-value record-element">Value</div>
          <div class="record-ttl record-element">TTL</div>
          <div class="record-priority record-element">Priority</div>
        </h3>
        """
    super options, data

    {domain} = @getData()
    @getListView().setData @getData()

  loadView:(mainView)->
    super
    {domain} = @getData()
    @instantiateListItems domain.dnsRecords  if domain.dnsRecords?
    
    @on "newRecordCreated", @bound "addItem"
    @getListView().on "recordDeletionRequested", @bound "deleteRecordItem"
    @getListView().on "recordUpdateRequested", @bound "updateRecordItem"

  deleteRecordItem:(recordItem)->
    {recordType, value, host} = recordItem.getData()
    {domain} = @getData()

    domain.deleteDNSRecord {recordType, value, host}, (err, response)=>
      unless err
        @removeItem recordItem
        return new KDNotificationView {title: "Record has been removed."}
      else
        log err
        return new KDNotificationView
          title : "An error occured while removing your record. Please try again."

  updateRecordItem:(oldData, recordItem)->
    {domain} = @getData()
    newData = recordItem.getData()

    if oldData.recordType isnt newData.recordType or oldData.host isnt newData.host
      # record type is changing, delete the old one & add the new one.
      domain.deleteDNSRecord oldData, (err, response)->
        console.log err  if err

        domain.createDNSRecord newData, (err, response)->
          console.log err  if err
          recordItem.refreshView()

    else
      domain.updateDNSRecord {oldData, newData}, (err, response)->
        unless err
          recordItem.refreshView()

        console.log err, response