kd = require 'kd'
React = require 'react'
Link  = require 'app/components/common/link'


module.exports = class SidebarMachine extends React.Component

  @propTypes =
    machine: React.PropTypes.object

  @defaultProps =
    machine : {}


  render: ->

    { label, slug, _id } = @props.machine

    <div className='SidebarMachine'>
      <Link
        className='SidebarMachine--title'
        key={_id}
        href="/IDE/#{label or slug}" >
        {label}
      </Link>
    </div>
