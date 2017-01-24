React = require 'react'
{ storiesOf, action } = require '@kadira/storybook'

CreditCard = require './CreditCard'

storiesOf 'CreditCard', module

  .add 'empty card', ->
    <CreditCard />

  .add 'regular card (visa/master/discover/etc.)', ->
    <CreditCard
      name='Frank Latte'
      number='4242424242424242'
      month='04'
      year='19'
      brand='visa' />

  .add 'half regular card (visa/master/discover/etc.)', ->

    children = [ 'visa', 'master-card', 'american-express', 'diners-club'
      'discover', 'jcb', 'maestro' ].map (brand, index) ->
        number = if 'american-express' is brand
        then '•••••••••••4242'
        else '••••••••••••4242'
        <div key={brand} style={{margin: '0 20px 20px 0', width: '260px'}}>
          <CreditCard
            name='Fahrettin Tasdelen'
            number={number}
            month='04'
            year='19'
            brand={brand} />
        </div>


    <div style={{width: '560px', margin: '0 auto', display: 'flex', flexWrap: 'wrap'}}>
      {children}
    </div>

  .add 'amex card', ->
    <CreditCard title='Credit Card Number' brand='amex' />
