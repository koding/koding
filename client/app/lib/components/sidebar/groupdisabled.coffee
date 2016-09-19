React = require 'react'
Link  = require 'app/components/common/link'
isAdmin = require 'app/util/isAdmin'

module.exports = SidebarGroupDisabled = ->

  message = if isAdmin()
    '''
    We hope you have enjoyed using Koding. Please enter a credit card
    to continue using Koding.
    '''
  else
    '''
    We hope you have enjoyed using Koding. Please ask one of your team
    administrators to enter a credit card to continue using Koding.
    '''


  <div className='SidebarTeamSection'>
    <Link className='SidebarSection-headerTitle' href='/Home/Stacks'>
      STACKS
    </Link>
    <section className='SidebarSection SidebarStackSection SidebarStackWidgets'>
      <div className='SidebarSection-body'>
        <p>{message}</p>
      </div>
    </section>
  </div>


