React = require 'app/react'
List = require 'app/components/list'
moment = require 'moment'
{ sortBy } = require 'lodash'

Label = require 'lab/Text/Label'

module.exports = class InvoicesList extends React.Component

  getInvoices: -> sortBy @props.invoices, (invoice) -> -1 * (Number invoice.period_end)

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
    <div style={flex: 1}>
      <Label>Monthly payment for {date.format 'MMMM YYYY'}</Label>
    </div>
    <Label>{date.format 'MM/DD/YYYY'}</Label>
    <Label>${total}</Label>
  </div>
