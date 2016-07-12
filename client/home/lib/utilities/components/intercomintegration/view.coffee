kd    = require 'kd'
React = require 'kd-react'


module.exports = class IntercomIntegrationView extends React.Component

  render: ->

    <p>
      <strong>Intercom Integration</strong>
      Enable Intercom.io for live chat with your team
      <span className='separator'></span>
      <cite className='warning'>
        For this integration you need to create an
        account at <a href='https://www.intercom.io' target='_blank'>intercom.io</a>.
        <br/><br/>
        Once you get your Intercom <code className='HomeAppView--code'>APP ID</code>
        and paste below, we will complete the integration for you.
      </cite>
      <filedset>
        <label>Intercom.io <code className='HomeAppView--code'>APP ID</code></label>
        <input
          type="text"
          className="kdinput text"
          value={@props.defaultValue}
          onChange={@props.onValueChange}
        />
        <a
          className="custom-link-view HomeAppView--button primary fr"
          href="#"
          onClick={@props.onSave}>
            <span className="title">SAVE</span>
        </a>
        <span className="clearfix" />
      </filedset>
    </p>
