class DNSRecordListController extends KDListViewController

  constructor:(options={}, data)->
    options = $.extend
      defaultItem :
        itemClass : EmptyDNSRecordListItemView
      itemClass   : DNSRecordListItemView
      viewOptions :
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
    , options
    super options, data

    {domain} = @getData()
    @instantiateListItems domain.dnsRecords  if domain.dnsRecords?

    @getListView().on "recordDeletionRequested", @bound "deleteRecordItem"
    @on "newRecordCreated", @bound "addItem"

  deleteRecordItem:(recordItem)->
    {recordType, value, host} = recordItem.getData()
    {domain} = @getData()

    domain.deleteDNSRecord {recordType, value, host}, (err, response)=>
      unless err
        @removeItem recordItem
      else
        new KDNotificationView
          title : "An error occured while removing your record. Please try again."

