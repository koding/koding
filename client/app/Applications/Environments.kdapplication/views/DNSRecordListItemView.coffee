class DNSRecordListItemView extends KDListItemView

  constructor:(options={}, data)->
    options.tagName = "tr"
    super options, data

    @editButton = new KDButtonView
      title    : "Edit"
      callback : @bound "editRecord"
    @deleteButton = new KDButtonView
      title    : "Delete"
      callback : @bound "deleteRecord"

  viewAppended: JView::viewAppended

  pistachio:->
    {recordType, host, value, ttl} = @getData()

    """
    <td>#{recordType}</td>
    <td>#{host}</td>
    <td>#{value}</td>
    <td>#{ttl}</td>
    <td>
      {{> @editButton }}
      {{> @deleteButton }}
    </td>
    """

  deleteRecord:->
    @getDelegate().emit "recordDeletionRequested", this

  editRecord:->



class EmptyDNSRecordListItemView extends DNSRecordListItemView

  pistachio:->
    """
    <td colspan="5">There is no DNS record for this domain.</td>
    """