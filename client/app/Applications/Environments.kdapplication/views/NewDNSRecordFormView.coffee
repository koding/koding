class NewDNSRecordFormView extends KDCustomHTMLView

  constructor:(options={}, data)->
    options.cssClass = "record-form-view"
    super options, data

    @typeLabel        = new KDLabelView
      title : "Record Type"

    @hostnameLabel    = new KDLabelView
      title : "Hostname"

    @destinationLabel = new KDLabelView
      title : "Points to"

    @ttlLabel         = new KDLabelView
      title : "TTL"

    @typeSelectBox    = new KDSelectBox
      selectOptions : [
        {title: "A", value: "A"}
        {title: "CNAME", value: "CNAME"}
        {title: "MX", value: "MX"}
        {title: "TXT", value: "TXT"}
        {title: "NS", value: "NS"}
        {title: "SRV", value: "SRV"}
        {title: "AAAA", value: "AAAA"}
      ]

    @hostnameInput    = new KDInputView
    @destinationInput = new KDInputView
    @ttlInput         = new KDInputView

    @addButton = new KDButtonView
      title    : "Add Record"
      callback : @bound "updateRecords"

  updateRecords:->
    {domain} = @getData()

    recordType = "A"#@typeSelectBox.getValue()
    hostname   = "www"#@hostnameInput.getValue()
    value      = "127.0.0.1"#@destinationInput.getValue()
    ttl        = @ttlInput.getValue()

    domain.createDNSRecord {recordType, hostname, value, ttl}, (err, record)=>
      console.log err, record
    


  viewAppended: JView::viewAppended

  pistachio:->
    """
      <section class="clearfix">
        <div class="input-container">
          {{> @typeLabel}}
          {{> @typeSelectBox }}
        </div>
        <div class="input-container">
          {{> @hostnameLabel}}
          {{> @hostnameInput }}
        </div>
        <div class="input-container">
          {{> @destinationLabel}}
          {{> @destinationInput }}
        </div>
        <div class="input-container">
          {{> @ttlLabel}}
          {{> @ttlInput }}
        </div>
        <div class="input-container">
          {{> @addButton }}
        </div>
      </section>
    """