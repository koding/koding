class DNSRecordListItemView extends KDListItemView

  constructor:(options={}, data)->
    options.tagName = "tr"
    super options, data

    @buildSubViews()

    @updateButton.hide()
    @cancelButton.hide()

  viewAppended: JView::viewAppended

  pistachio:->
    {recordType, host, value, ttl} = @getData()
    """
    <td>{{> @recordView }}</td>
    <td>{{> @recordHostView }}</td>
    <td>{{> @recordValueView }}</td>
    <td>{{> @recordTtlView }}</td>
    <td>
      {{> @editButton }}
      {{> @deleteButton }}
      {{> @updateButton }}
      {{> @cancelButton }}
    </td>
    """

  buildSubViews:->
    {recordType, host, value, ttl, priority} = @getData()

    @editButton = new KDButtonView
      title    : "Edit"
      callback : @bound "editRecord"

    @deleteButton = new KDButtonView
      title    : "Delete"
      callback : @bound "deleteRecord"

    @updateButton = new KDButtonView
      title        : "Update Record"
      callback     : @bound "updateRecord"

    @cancelButton = new KDButtonView
      title        : "Cancel"
      callback     : @bound "cancelEdit"

    @recordView      = new RecordTypeView {}, {recordType}
    @recordHostView  = new RecordHostView {}, {host}
    @recordValueView = new RecordValueView {}, {value}
    @recordTtlView   = new RecordTtlView {}, {ttl}

  emitEventToSubViews:(eventName)->
    for i in [0..3] # only to the first 4
      subView = @subViews[i]
      subView.emit eventName

  cancelEdit:->
    @emitEventToSubViews "editCancelled"
    @replaceButtons()

  replaceButtons:(isEditing)->
    if isEditing
      @editButton.hide()
      @deleteButton.hide()
      @updateButton.show()
      @cancelButton.show()
    else
      @updateButton.hide()
      @cancelButton.hide()
      @editButton.show()
      @deleteButton.show()

  deleteRecord:->
    @getDelegate().emit "recordDeletionRequested", this

  editRecord:->
    @emitEventToSubViews "editRequested"
    @replaceButtons true

  updateRecord:->
    data = @getData()
    oldData = $.extend {}, data # should be a better way to handle copying

    [recordTypeView, hostView, valueView, ttlView] = @subViews

    data.recordType = recordTypeView.getInputValue()
    data.host = hostView.getInputValue()
    data.value = valueView.getInputValue()
    data.ttl = ttlView.getInputValue()

    @setData data
    @getDelegate().emit "recordUpdateRequested", oldData, this

  refreshView:->
    @destroySubViews()
    @buildSubViews() # re-generate views with new data
    @replaceButtons()
    @viewAppended()


class RecordElementView extends JView

  constructor:(options={}, data)->
    super options, data

    @on "editRequested", ->
      @viewElm.hide()
      @formElmView.show()

    @on "editCancelled", ->
      @viewElm.show()
      @formElmView.hide()

    @on "editCompleted", ->
      @viewElm.show()
      @formElmView.hide()

  viewAppended:->
    super
    @formElmView.hide()

  getInputValue:->
    @formElmView.getValue()

  pistachio:->
    """
      <p>{{> @viewElm }}</p>
      {{> @formElmView }}
    """


class RecordTypeView extends RecordElementView

  constructor:(options={}, data)->
    super options, data

    {recordType} = @getData()

    @formElmView = new KDSelectBox
      cssClass      : 'editable'
      selectOptions : [
        {title: "A", value: "A"}
        {title: "CNAME", value: "CNAME"}
        {title: "MX", value: "MX"}
        {title: "TXT", value: "TXT"}
        {title: "NS", value: "NS"}
        {title: "SRV", value: "SRV"}
        {title: "AAAA", value: "AAAA"}
      ]
      defaultValue : recordType

    @viewElm = new KDCustomHTMLView
      partial : recordType


class RecordHostView extends RecordElementView
  constructor:(options={}, data)->
    super options, data

    {host} = @getData()

    @viewElm = new KDCustomHTMLView
      partial : host

    @formElmView = new KDInputView
      cssClass     : 'editable'
      defaultValue : host


class RecordValueView extends RecordElementView
  constructor:(options={}, data)->
    super options, data

    {value} = @getData()

    @viewElm = new KDCustomHTMLView
      partial : value

    @formElmView = new KDInputView
      cssClass     : 'editable'
      defaultValue : value


class RecordTtlView extends RecordElementView
  constructor:(options={}, data)->
    super options, data

    {ttl} = @getData()

    @viewElm = new KDCustomHTMLView
      partial : ttl

    @formElmView = new KDInputView
      cssClass     : 'editable'
      defaultValue : ttl


class EmptyDNSRecordListItemView extends DNSRecordListItemView

  pistachio:->
    """
    <td colspan="5">There is no DNS record for this domain.</td>
    """