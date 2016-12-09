React = require 'app/react'
SupportPlansList = require './view'

module.exports = class SupportPlansContainer extends React.Component
  
  getSupportPlans: ->

    return plans = [
      {
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
      {
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
      {
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
    ]


  render: ->

    <SupportPlansList 
      plans={@getSupportPlans()} />

