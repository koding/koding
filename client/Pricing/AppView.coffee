class PricingAppView extends KDView

  addWorkflow: (@workflow) ->
    @addSubView @workflow
    @workflow.on 'Finished', @bound "showThankYou"
    @workflow.on 'Cancel', @bound "showCancellation"

  hideWorkflow: ->
    @workflow.hide()

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

  checkSlug: ->
    slug      = @groupForm.inputs.GroupUrl
    slugView  = @groupForm.inputs.Slug
    tmpSlug   = slug.getValue()

    if tmpSlug.length > 2
      slugy = KD.utils.slugify tmpSlug
      KD.remote.api.JGroup.suggestUniqueSlug slugy, (err, newSlug)->
        slugView.updatePartial "#{location.protocol}//#{location.host}/#{newSlug}"
        slug.setValue newSlug

  showCancellation: ->
    @hideWorkflow()
    return  if @cancellation
    @cancellation = new KDView partial: "<h1>This order has been cancelled.</h1>"
    @addSubView @cancellation
