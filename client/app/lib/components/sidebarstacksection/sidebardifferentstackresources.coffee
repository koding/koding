kd                  = require 'kd'
Link                = require 'app/components/common/link'
EnvironmentFlux     = require 'app/flux/environment'
React               = require 'app/react'
classnames          = require 'classnames'


module.exports = class SidebarDifferentStackResources extends React.Component

  @defaultProps =
    className   : 'SidebarStackWidgets --DifferentStackResources'

  onClick: (event) ->

    kd.utils.stopDOMEvent event
    EnvironmentFlux.actions.reinitStackFromWidget()


  # this is at best a notification, we shouldn't put this on
  # top of the sidebar as a forcing function. if we do, there should be "hide this" option
  # i'd argue that we should remove this completely for now.
  # users should go to stack catalogue, select whatever stack they like.
  # on top of that, we say "go re-init your default stack", re-init means
  # re-init the current one, this action changes the current with the new
  # default thereby it's very confusing.
  render: ->

    <section className={classnames 'SidebarSection', @props.className}>
      <div className='SidebarSection-body'>
        <p>
          Team admin has changed the default stack.
          Please save your changes and reinitialize to get latest stack
        </p>
        <Link onClick={@bound 'onClick'}>
          Reinitialize Default Stack
        </Link>
      </div>
    </section>
