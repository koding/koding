_              = require 'lodash'
kd             = require 'kd'
JView          = require 'app/jview'
KodingSwitch   = require 'app/commonviews/kodingswitch'
CustomLinkView = require 'app/customlinkview'


module.exports = class HomeUtilitiesCustomerFeedback extends kd.CustomHTMLView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    super options, data

    team          = kd.singletons.groupsController.getCurrentGroup()
    { customize } = team
    id            = customize?.chatlioId

    @input = new kd.InputView
      defaultValue : id  if id

    @guide = new CustomLinkView
      cssClass : 'HomeAppView--button'
      title    : 'VIEW GUIDE'
      href     : 'https://www.koding.com/docs/chatlio'

    @save = new CustomLinkView
      cssClass : 'HomeAppView--button primary fr'
      title    : 'SAVE'
      click    : =>
        id = @input.getValue().trim()
        team.modify { 'customize.chatlioId': id }, (err) ->
          new kd.NotificationView if err
          then { title: 'There was an error, please try again!' }
          else
            if id
            then { title: 'Chatlio id successfully saved!' }
            else { title: 'Chatlio integration successfully turned off!' }


  pistachio: ->
    """
    <p>
    <strong>Customer Feedback</strong>
    Enable Chatlio.com for real-time customer feedback
    <span class='separator'></span>
    <cite class='warning'>
      Chatlio will allow you to talk with your team members using your
      existing Slack service. For this integration you need to create an
      account at <a href='chatlio.com' target='_blank'>chatlio.com</a>. * Requires Slack integration.
      <br/><br/>
      Once you get your Chatlio <code class='HomeAppView--code'>data-widget-id</code>
      and paste below, we will complete the integration for you.
    </cite>
    <filedset>
    <label>Chatlio.com <code class='HomeAppView--code'>data-widget-id</code></label>
    {{> @input}}
    {{> @save}}
    {{> @guide}}
    </p>
    """