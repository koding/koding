kd               = require 'kd'
React            = require 'kd-react'
List             = require 'app/components/list'


module.exports = class KDCliView extends React.Component

  renderKDInstallView: ->
    <div>
      <p>
        <code className="HomeAppView--code">kd</code>  is a command line program that allows you to use your local
          IDE with your VMs. Copy and paste the command below into your terminal.
      </p>
      <code className="HomeAppView--code block">
        <span ref='codeblock' onClick={@props.onCMDClick}>
          {@props.cmd}
        </span>
        <cite>{@props.copyKey}</cite>
      </code>
      <p>Once installed, you can use <code className="HomeAppView--code">kd list</code> to list your Koding VMs and 
        <code className="HomeAppView--code">kd mount</code> to mount your VM to a local folder in your computer.
        For detailed instructions:
      </p>
      <p className='view-guide'>
        <a className='HomeAppView--button primary' href='https://www.koding.com/docs/connect-your-machine' target='_blank'>VIEW GUIDE</a>
      </p>
    </div>


  render: ->
  
    <div>
      {@renderKDInstallView()}
    </div>