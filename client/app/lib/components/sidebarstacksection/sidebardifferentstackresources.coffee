kd                  = require 'kd'
Link                = require 'app/components/common/link'
React               = require 'kd-react'
SidebarSection      = require 'app/components/sidebarsection'
KDReactorMixin      = require 'app/flux/base/reactormixin'


module.exports = class SidebarDifferentStackResources extends React.Component

  @defaultProps =
    className   : 'SidebarStackWidgets --DifferentStackResources'


  handleOnClick: ->

    # Legacy class.
    kd.singletons.router.handleRoute '/Stacks'


  render: ->
    <SidebarSection
      className={@props.className}
      title='Stacks' >
      <div>
        <p>
          You have different resources in your stacks.
          Please re-initialize your stacks.
        </p>
        <Link onClick={@bound 'handleOnClick'}>
          Show Stacks
        </Link>
      </div>
    </SidebarSection>
