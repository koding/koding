kd                      = require 'kd'
React                   = require 'kd-react'
Link                    = require 'app/components/common/link'
ReactDOM                = require 'react-dom'
ActivityFlux            = require 'activity/flux'
SidebarSection          = require 'app/components/sidebarsection'
isUserGroupAdmin        = require 'app/util/isusergroupadmin'
showErrorNotification   = require 'app/util/showErrorNotification'


module.exports = class SidebarNoStacks extends React.Component


  render: ->

    <div className='SidebarTeamSection'>
      <Link className='SidebarSection-headerTitle' href='/Welcome'>
        STACKS
      </Link>
      <section className='SidebarSection SidebarStackSection SidebarStackWidgets'>
        <div className='SidebarSection-body'>
          <p>
            Your stacks has not been
            fully configured yet, please
            finalize onboarding steps.
          </p>
          <Link href='/Welcome'>Finalize steps</Link>
        </div>
      </section>
    </div>
