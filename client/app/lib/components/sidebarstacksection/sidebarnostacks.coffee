React = require 'app/react'
Link  = require 'app/components/common/link'


module.exports = class SidebarNoStacks extends React.Component

  renderMessage: ->

    { hasTemplate, hasPermission } = @props

    if hasTemplate
      <p>
        Open your dashboard and add your stacks to sidebar to continue.
      </p>
    else if hasPermission
      <p>
        Your stacks has not been fully configured yet, please finalize
        onboarding steps.
      </p>
    else
      <p>
        Your stacks has not been fully configured yet, please wait until your
        admin sets them up for you.
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
