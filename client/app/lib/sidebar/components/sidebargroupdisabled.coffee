React = require 'react'
Link  = require 'app/components/common/link'
isAdmin = require 'app/util/isAdmin'

module.exports = SidebarGroupDisabled = ->

  message = if isAdmin()
    '''
    We hope you have enjoyed using Koding. Please enter a credit card
    to continue.
    '''
  else
    '''
    We hope you have enjoyed using Koding. Please ask one of your team
    administrators to enter a credit card to continue using Koding.
    '''


  <div className='SidebarTeamSection'>
    <Link className='SidebarSection-headerTitle' href='/Home/stacks'>
      STACKS
    </Link>
    <section className='SidebarSection SidebarStackSection SidebarStackWidgets'>
      <div className='SidebarSection-body'>
        <p>{message}</p>
        {if isAdmin()
          <a href='/Home/team-billing'>Go to Team Billing</a>}
      </div>
    </section>
  </div>