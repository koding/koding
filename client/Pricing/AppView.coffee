class PricingAppView extends KDView

  viewAppended: ->
    @addSubView @getOptions().workflow

  hideWorkflow: ->
    @getOptions().workflow.hide()

  showThankYou: (data) ->
    @hideWorkflow()

    @thankYou = new KDCustomHTMLView
      partial:
        """
        <h1>Thank you!</h1>
        <p>
          Your order has been processed.
        </p>
        #{
          if data.createAccount
          then "<p>Please check your email for your registration link.</p>"
          else "<p>We hope you enjoy your new subscription</p>"
        }
        """

    unless data.createAccount
      @thankYou.addSubView @getContinuationLinks()

    @addSubView @thankYou

  getContinuationLinks: ->
    new KDCustomHTMLView partial:
      """
      <ul>
        <li><a href="/Activity">Activity</a></li>
        <li><a href="/Account">Account</a></li>
        <li><a href="/Account/Subscriptions">Subscriptions</a></li>
        <li><a href="/Environments">Environments</a></li>
      </ul>
      """


  showCancellation: ->
    @hideWorkflow()

    @cancellation = new KDView
      partial:
        """
        <h1>This order has been cancelled.</h1>
        """

    @addSubView @cancellation