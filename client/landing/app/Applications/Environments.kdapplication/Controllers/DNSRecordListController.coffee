class DNSRecordListController extends KDListViewController

  constructor:(options={}, data)->
    super options, data

    @on "newRecordCreated", @bound 'addItem'

    @fetchRecords()

  fetchRecords:->
    {domain} = @getData()

    domain.fetchDNSRecords (err, records)=>
      console.log records
      @instantiateListItems records

  refreshRecords:->
    @removeAllItems()
    @fetchRecords()

