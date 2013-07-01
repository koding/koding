class DNSRecordListController extends KDListViewController

  constructor:(options={}, data)->

    options.itemClass   or= DNSRecordListItemView
    options.defaultItem or=
      itemClass : EmptyDNSRecordListItemView
    options.viewOptions or=
      type      : 'dns-records'
      tagName   : 'table'
      partial   :
        """
        <thead>
          <tr>
            <th>Record Type</th>
            <th>Host</th>
            <th>Value</th>
            <th>TTL</th>
            <th>Actions</th>
          </tr>
        </thead>
        """
    super options, data

    {domain} = @getData()
    @getListView().setData @getData()
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
      else
        new KDNotificationView
          title : "An error occured while removing your record. Please try again."

  updateRecordItem:(oldData, recordItem)->
    {domain} = @getData()
    newData = recordItem.getData()

    console.log 'updating the record', oldData, ' with ', newData

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