React = require 'react'
{ storiesOf, action } = require '@kadira/storybook'
Button = require 'lab/Button'
Box = require 'lab/Box'
SupportPlan = require 'lab/SupportPlan'

storiesOf 'SupportPlan', module

  .add 'Basic', ->

    plan = {
      name : 'Basic'
      price : '1,000'
      period : 'month'
      features : [
        '4 Hours dedicated support'
        'Stack script support'
        '24 Hours response time'
        'General Troubleshooting'
      ]
    }
    <SupportPlan
          name={plan.name}
          price={plan.price}
          period={plan.period}
          type={'activation'}
          features={plan.features}
          onActivationButtonClick={action 'Basic activate clicked'} />

  .add 'Business Switch', ->

    plan = {
      name : 'Business'
      price : '5,000'
      period : 'month'
      features : [
        '25 Hours dedicated support'
        'Stack script support'
        '4 Hours response time'
        'General Troubleshooting'
      ]
    }
    <SupportPlan
          name={plan.name}
          price={plan.price}
          period={plan.period}
          type={'switch'}
          features={plan.features}
          onActivationButtonClick={action 'Business activate clicked'} />

  .add 'Enterprise Contact Us', ->

    plan = {
      name : 'Enterprise'
      price : null
      period : null
      features : [
        'On-premise installation'
        'On-site support'
        'Phone support'
        '24/7 Coverage'
      ]
    }
    <SupportPlan
          name={plan.name}
          price={plan.price}
          period={plan.period}
          type={'activation'}
          features={plan.features}
          onActivationButtonClick={action 'Enterprise activate clicked'} />

  .add 'Enterprise Active', ->

    plan = {
      name : 'Enterprise'
      price : null
      period : null
      features : [
        'On-premise installation'
        'On-site support'
        'Phone support'
        '24/7 Coverage'
      ]
    }
    <SupportPlan
          name={plan.name}
          price={plan.price}
          period={plan.period}
          type={'active'}
          features={plan.features}
          onActivationButtonClick={action 'Enterprise activate clicked'} />
