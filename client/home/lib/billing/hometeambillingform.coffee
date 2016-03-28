kd        = require 'kd'
JView     = require 'app/jview'
InputMask = require 'inputmask-core'

module.exports = class HomeTeamBillingForm extends kd.FormView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'HomeAppView--billing-form', options.cssClass

    super options, data

    @ccNumber     = new kd.InputView
    @ccMonth      = new kd.InputView
    @ccYear       = new kd.InputView
    @ccCvc        = new kd.InputView
    @ccName       = new kd.InputView
    @ccNameChange = new kd.InputView
    @fullName     = new kd.InputView
    @address      = new kd.InputView
    @unit         = new kd.InputView
    @zip          = new kd.InputView
    @city         = new kd.InputView
    @state        = new kd.InputView
    @phone        = new kd.InputView


  pistachio: ->

    """
    <h2>Payment Information</h2>
    <figure class='HomeAppView--cc'>
      <label>Card Number</label>
      {{> @ccNumber}}
      <fieldset class='wrapper--expiration'>
        <label>Expiration</label>
        {{> @ccMonth}}
        {{> @ccYear}}
      </fieldset>
      <fieldset class='wrapper--cvc'>
        <label>CVC</label>
        {{> @ccCvc}}
      </fieldset>
    </figure>
    <section class='HomeAppView--section payment'>
      <fieldset>
        <label>Nickname:</label>
        {{> @ccName}}
        {{> @ccNameChange}}
      </fieldset>
    </section>
    <h2>Billing Information</h2>
    <section class='HomeAppView--section billing'>
      <fieldset>
        <label>Full Name:</label>
        {{> @fullName}}
      </fieldset>
      <fieldset>
        <label>Address:</label>
        {{> @address}}
        {{> @unit}}
      </fieldset>
      <fieldset>
        <label>Zip Code:</label>
        {{> @zip}}
        {{> @city}}
        {{> @state}}
      </fieldset>
      <fieldset>
        <label>Phone number:</label>
        {{> @phone}}
      </fieldset>
    </section>
    """