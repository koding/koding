class PricingProductForm extends JView
  constructor: (options = {}, data) ->
    options.cssClass = KD.utils.curry "product-form", options.cssClass
    super options, data

    @developerPlan = new DeveloperPlan
    @developerPlan.on "PlanSelected", @bound "selectPlan"
    @developerPlan.on "ShowHowItWorks", =>
      @$(".how-it-works").removeClass "team"
      @showHowItWorks()

    @teamPlan = new TeamPlan cssClass: "hidden"
    @teamPlan.on "PlanSelected", @bound "selectPlan"
    @teamPlan.on "ShowHowItWorks", =>
      @$(".how-it-works").addClass "team"
      @showHowItWorks()

    @forwardEvent @developerPlan, "CurrentSubscriptionSet"
    @forwardEvent @teamPlan, "CurrentSubscriptionSet"

    @toggle        = new KDMultipleChoice
      cssClass     : "pricing-toggle"
      labels       : ["DEVELOPER", "TEAM"]
      multiple     : no
      callback     : =>
        KD.singleton("router").handleRoute switch @toggle.getValue()
            when "DEVELOPER" then "/Pricing/Developer"
            when "TEAM" then "/Pricing/Team"

  showDeveloperPlan: ->
    @toggle.setValue "DEVELOPER"
    @developerPlan.show()
    @teamPlan.hide()

  showTeamPlan: ->
    @toggle.setValue "TEAM"
    @developerPlan.hide()
    @teamPlan.show()

  showHowItWorks: ->
    @$(".how-it-works").removeClass "hidden"

  selectPlan: (tag, options) ->
    KD.singleton("paymentController").fetchSubscriptionsWithPlans tags: [tag], (err, subscriptions) =>
      return KD.showError "You are already subscribed to this plan"  if subscriptions.length
      KD.remote.api.JPaymentPlan.one tags: $in: [tag], (err, plan) =>
        return  if KD.showError err
        @emit "PlanSelected", plan, options

  pistachio: ->
    """
    <div class="inner-container">
      <header class="clearfix">
        <h1>Your Dedicated Koding</h1>
        <h2>Flexible Pricing for Developers and Teams</h2>
        <p>
          Your virtual machines (VMs) run on servers in our Premium cluster that are dedicated to our paying customers,
          so you won't be affected by network disruptions and traffic spikes that can happen on our free cluster.
          This cluster also has less users per server than our free clusters so you are less likely to be disturbed by a "noisy neighbor".
          <br><br>
          If you want us to deploy Koding to your own servers, please contact us for our Enterprise plans.
        </p>
        {{> @toggle}}
      </header>
      <div class="plan-selection">
        {{> @developerPlan}}
        {{> @teamPlan}}
      </div>
      <section class="how-it-works hidden">
        <div class="item cpu">
          <h4>CPU</h4>
          <p>
            Your CPUs are shared among all your running VMs.

            <br><br>

            If you run only one VM, all CPUs will be utilized; if you have 10 VMs running, they will share your available CPUs.
            This is not a problem for development environments.  It's designed to reduce your costs,
            because you don't normally need 100% CPU from all your servers at the same time.

            <br><br>

            You should make your own calculations, determine how many CPUs you need at any given time,
            and choose your plan accordingly.
            This simply allows you to pay for the minimum number of CPUs needed.

            <br><br>

            Say you have 10 developers in your group, five of whom are online at night, with the other five active in the mornings.
            You would need a plan with 5 CPUs; you don't have to pay for 10.
            You can even get by with less if they're doing web development, but you may need more if they are data mining.
          </p>
        </div>
        <div class="item">
          <h4>RAM</h4>
          <p>
            Memory is shared between your running VMs.  Each VM starts with allocated memory.

            <br><br>

            If you have 10GB limit, you can run 10VMs at 1GB, or 3 x 3GB and 1 x 1GB.
            (We only provide 1GB VMs for now - however you will soon be able to create VMs of any size you require.)
          </p>
        </div>
        <div class="item">
          <h4>Always On VM</h4>
          <p>
            All Koding VMs are optimized for software development,
            and they're automatically turned off one hour after you leave the site.

            <br><br>

            If you want your VM to stay online, you can mark it as "Always on", and we will never turn it off.

            <br><br>

            This is great for lightweight sites, your personal blog perhaps, or your client presentations.
            We are not attempting to be a production host, so if you are looking for 24x7x365 availability
            we might suggest you host your application/site with a specialist hosting company.
          </p>
        </div>
        <div class="item">
          <h4>Total VMs</h4>
          <p>
            The maximum number of VMs that you can create.  For example, if your total VM quota is 10,
            and you have 3GB RAM available, you can only run 3 x 1GB RAM, and you will have 7 VMs that are turned off.

            <br><br>

            This allows you to work on different environments, by turning on and off different setups that you create.
            VMs that are turned-off will take away from your storage quota, not from CPU or RAM.
          </p>
        </div>
        <div class="item">
          <h4>Disk</h4>
          <p>
            This is local storage allocated to your VMs. You can distribute this quota across all of your VMs as you need.

            <br><br>

            You can allocate 40GB of disk space to one of your VMs, for instance, and to the next one you could allocate 10GB.
          </p>
        </div>
      </section>
    </div>
    """
