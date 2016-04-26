React = require 'kd-react'
List = require 'app/components/list'
moment = require 'moment'

module.exports = class InvoicesList extends React.Component

  numberOfSections: -> 1

  numberOfRowsInSection: -> @props.invoices?.size * 3

  renderSectionHeaderAtIndex: -> null

  renderRowAtIndex: (sectionIndex, rowIndex) -> <SingleInvoice invoice={@props.invoices.get 0} />

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

  date = moment(new Date(invoice.get 'periodEnd'))

  <div className="HomeAppViewListItem SingleInvoice">
    <div className='HomeAppViewListItem-label'>
      <InvoiceLabel invoiceDate={date} />
    </div>
    <div className='HomeAppViewListItem-SecondaryContainer'>
      <span className='SecondaryContainerItem'>{date.format 'MM/DD/YYYY'}</span>
      <span className='SecondaryContainerItem'>${invoice.get 'amount'}</span>
    </div>
  </div>


InvoiceLabel = ({ invoiceDate }) ->

  <span className='InvoiceLabel'>{invoiceDate.format 'MMMM'} Subscription</span>


