kd = require 'kd'
React = require 'app/react'
cx = require 'classnames'

Link = require 'app/components/common/link'


module.exports = class DefaultStackUpdated extends React.Component

  @defaultProps =
    className: 'SidebarStackWidgets --DifferentStackResources'


  onClick: (event) ->

    kd.utils.stopDOMEvent event
    kd.singletons.computeController.reinitStack()


  render: ->

    <section className={@props.className}>
      <div className='SidebarSection-body'>
        <p>
          Team admin has changed the default stack.
          Please save your changes and reinitialize to get latest stack.
        </p>
        <Link onClick={@bound 'onClick'}>
          Reinitialize Default Stack
        </Link>
      </div>
    </section>
