kd    = require 'kd'
React = require 'app/react'


module.exports = class IntercomIntegrationView extends React.Component

  render: ->

    <div className='HomeAppView--sectionWrapper'>
      <strong>Intercom</strong>
      Enable Intercom.io for live chat, feedback, support and more.
      <span className='separator'></span>
      <cite className='warning'>
        It's a customer communication platform with a suite of integrated
        products for every team—including sales, marketing, product, and support.
        For this integration you need to create an
        account at <a href='https://www.intercom.io' target='_blank'>intercom.io</a>.
        <br/><br/>
        Once you get your Intercom <code className='HomeAppView--code'>APP ID</code> and
        paste below, we will complete the integration for you.
      </cite>
      <fieldset>
        <label>Intercom.io <code className='HomeAppView--code'>APP ID</code></label>
        <input
          type="text"
          className="kdinput text"
          value={@props.defaultValue or ''}
          onChange={@props.onValueChange}
        />
        <a
          className="custom-link-view HomeAppView--button primary fr"
          href="#"
          onClick={@props.onSave}>
            <span className="title">SAVE</span>
        </a>
        <GuideButton />
      </fieldset>
    </div>


GuideButton = ->

  <a className="custom-link-view HomeAppView--button" href="https://www.koding.com/docs/intercom">
    <span className="title">VIEW GUIDE</span>
  </a>
