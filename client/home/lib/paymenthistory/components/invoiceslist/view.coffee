React = require 'app/react'
List = require 'app/components/list'
moment = require 'moment'
{ sortBy, map, filter } = require 'lodash'

Label = require 'lab/Text/Label'

module.exports = class InvoicesList extends React.Component

  getInvoices: ->

    invoices = sortBy @props.invoices, (i) -> -1 * (Number i.period_end)
    invoices = map invoices, (i) -> i.set 'total', (i.total / 100).toFixed 2
    invoices = filter invoices, (i) -> i.paid

  numberOfSections: -> 1

  numberOfRowsInSection: -> @getInvoices().length

  renderSectionHeaderAtIndex: -> null

  renderRowAtIndex: (sectionIndex, rowIndex) ->
    <SingleInvoice invoice={@getInvoices()[rowIndex]} />

  renderEmptySectionAtIndex: -> <div>No invoices found</div>

  render: ->
    <List
      numberOfSections={@bound 'numberOfSections'}
      rowClassName='HomeTeamBillingInvoicesList-row'
      numberOfRowsInSection={@bound 'numberOfRowsInSection'}
      renderSectionHeaderAtIndex={@bound 'renderSectionHeaderAtIndex'}
      renderRowAtIndex={@bound 'renderRowAtIndex'}
      renderEmptySectionAtIndex={@bound 'renderEmptySectionAtIndex'}
    />


SingleInvoice = ({ invoice }) ->

  { period_end, total } = invoice

  date = moment(new Date period_end * 1000)

  <div className="HomeAppViewListItem SingleInvoice">
    <div style={flex: 4}>
      <Label>Monthly payment for {date.format 'MMMM YYYY'}</Label>
    </div>
    <div style={flex: 2, textAlign: 'right'}>
      <Label>{date.format 'MM/DD/YYYY'}</Label>
    </div>
    <div style={flex: 1, textAlign: 'right'}>
      <Label>${total}</Label>
    </div>
  </div>
