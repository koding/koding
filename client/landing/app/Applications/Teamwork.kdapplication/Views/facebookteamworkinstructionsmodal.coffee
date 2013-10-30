class FacebookTeamworkInstructionsModal extends KDModalViewWithForms

  constructor: (options = {}, data) ->

    options.title                  = "Before Starting"
    options.cssClass               = "tw-before-starting-modal"
    options.width                  = 700
    options.overlay                = yes
    options.overlayClick           = no
    options.tabs                   =
      navigable                    : no
      forms                        :
        "Create New App"           :
          fields                   :
            createApp              :
              itemClass            : KDView
              cssClass             : "step"
              partial              : """
                <p class="tw-modal-line">1. Visit <strong><a href="http://developers.facebook.com/apps">http://developers.facebook.com/apps</a></strong> and click the <strong>Create New App</strong> button in the top right corner.</p>
                <div class="tw-modal-image">
                  <img src="/images/teamwork/facebook/step1.jpg" />
                </div>
                <p class="tw-modal-line">2. Then fill out <strong>App Name</strong>, <strong>App Namespace</strong> and <strong>App Category</strong> fields. Once that is done, click <strong>Continue</strong> button.</p>
                <div class="tw-modal-image step1">
                  <img class="tw-fb-step1" src="/images/teamwork/facebook/step2.jpg" />
                </div>
                <p class="tw-modal-line">3. Once that is done, click the <strong>Next</strong> button on this page.</p>
              """
          buttons                  :
            Next                   :
              cssClass             : "modal-clean-green"
              callback             : =>
                @modalTabs.showPaneByIndex 1
        "App Setup"                :
          fields                   :
            image                  :
              itemClass            : KDView
              cssClass             : "step"
              partial              : """
                <div class="tw-modal-image step-general">
                  <p class="tw-modal-line">1. Find your <strong>App ID</strong> and <strong>Namespace</strong> and copy below.</p>
                  <img src="/images/teamwork/facebook/step4.jpg" />
                </div>
              """
            appId                  :
              placeholder          : "Enter you App ID"
              label                : "App ID"
              validate             :
                rules              :
                  required         : yes
                messages           :
                  required         : "Please enter your App ID"
            appNamespace           :
              placeholder          : "Enter you App Namespace"
              label                : "App Namespace"
              validate             :
                rules              :
                  required         : yes
                messages           :
                  required         : "Please enter your App Namespace"
            canvasUrlText          :
              itemClass            : KDView
              cssClass             : "step"
              partial              : """
                <p>2. Copy the Canvas URL link below, and go back to Facebook. Scroll down to the <strong>Canvas URL</strong> under <strong>App on Facebook</strong> tab and paste the link you just copied into the field.</p>
              """
            appCanvasUrl           :
              label                : "Canvas URL"
              attributes           :
                readonly           : "readonly"
              defaultValue         : "https://#{KD.nick()}.kd.io/Teamwork/Facebook/"
            text                   :
              itemClass            : KDView
              cssClass             : "step"
              partial              : """
                <div class="tw-modal-image step-general">
                  <img src="/images/teamwork/facebook/step3.jpg" />
                </div>
              """
          buttons                  :
            Done                   :
              cssClass             : "modal-clean-green"
              callback             : =>
                {appId, appNamespace, appCanvasUrl} = @modalTabs.forms["App Setup"].inputs
                if appId.validate() and appNamespace.validate()
                  @getDelegate().emit "FacebookAppInfoTaken",
                    appId          : appId.getValue()
                    appNamespace   : appNamespace.getValue()
                    appCanvasUrl      : appCanvasUrl.getValue()
                    @destroy()

    super options, data
