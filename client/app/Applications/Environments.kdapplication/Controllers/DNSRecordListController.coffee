class DNSRecordListController extends KDListViewController

  constructor:(options={}, data)->
    super options, data

    @on "newRecordCreated", @bound 'addItem'

    @fetchRecords()

  fetchRecords:->
    {domain} = @getData()

    domain.fetchDNSRecords (err, records)=>
      @instantiateListItems records if records

  refreshRecords:->
    @removeAllItems()
    @fetchRecords()

