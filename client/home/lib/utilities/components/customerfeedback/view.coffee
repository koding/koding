kd               = require 'kd'
React            = require 'kd-react'


module.exports = class CustomerFeedBackView extends React.Component

  render: ->

    <p>
      <strong>Customer Feedback</strong>
      Enable Chatlio.com for real-time customer feedback
      <span className='separator'></span>
      <cite className='warning'>
        Chatlio will allow you to talk with your team members using your
        existing Slack service. For this integration you need to create an
        account at <a href='chatlio.com' target='_blank'>chatlio.com</a>. * Requires Slack integration.
        <br/><br/>
        Once you get your Chatlio <code className='HomeAppView--code'>data-widget-id</code>
        and paste below, we will complete the integration for you.
      </cite>
      <filedset>
        <label>Chatlio.com <code className='HomeAppView--code'>data-widget-id</code></label>
        <InputArea value={@props.defaultValue} callback={@props.onInputAreaChange} />
        <SaveButton callback={@props.handleSaveButton} />
        <GuideButton />
      </filedset>
    </p>


InputArea = ({ value, callback }) ->

   <input type="text"
    className="kdinput text "
    value={value}
    onChange={callback}/>


SaveButton = ({ callback }) ->

  <a className="custom-link-view HomeAppView--button primary fr" href="#" onClick={callback}>
    <span className="title">SAVE</span>
  </a>


GuideButton = ->

  <a className="custom-link-view HomeAppView--button" href="https://www.koding.com/docs/chatlio">
    <span className="title">VIEW GUIDE</span>
  </a>
