React = require 'app/react'
Link  = require 'app/components/common/link'
canCreateStacks = require 'app/util/canCreateStacks'
isAdmin = require 'app/util/isAdmin'


module.exports = class SidebarNoStacks extends React.Component

  renderMessage: ->

    { teamStacks, privateStacks } = @props

    if teamStacks or privateStacks
      <p>
        Open your dashboard and add your stacks to sidebar to continue
      </p>
    else if canCreateStacks()
      <p>
        Your stacks has not been
        fully configured yet, please
        finalize onboarding steps.
      </p>
    else
      <p>
        Your stacks has not been
        fully configured yet, please
        wait until your admin sets
        them up for you.
      </p>



  render: ->

    <div className='SidebarTeamSection'>
      <Link className='SidebarSection-headerTitle' href='/Home/stacks'>
        STACKS
      </Link>
      <section className='SidebarSection SidebarStackSection SidebarStackWidgets'>
        <div className='SidebarSection-body'>
          {@renderMessage()}
        </div>
      </section>
    </div>
