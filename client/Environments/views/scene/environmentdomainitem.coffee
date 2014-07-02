class EnvironmentDomainItem extends EnvironmentItem

  constructor:(options={}, data)->

    options.cssClass           = 'domain'
    options.joints             = ['right']

    options.allowedConnections =
      EnvironmentMachineItem   : ['left']

    super options, data

    {@domain} = @getData()


  updateStateStyle:->
    if @domain.domain?
    then @setClass 'verified'
    else @unsetClass 'verified'


  confirmDestroy:->

    @deletionModal = new DomainDeletionModal {}, @domain
    @deletionModal.on "domainRemoved", @bound 'destroy'


  activateDomain:->

    new KDNotificationView title: "FIXME GG~"

  viewAppended:->

    @updateStateStyle()

    @activateButton = new KDButtonView
      title    : "Activate"
      cssClass : "solid green mini"
      callback : @bound 'activateDomain'

    super

  pistachio:->
    """
      <div class='details'>
        <span class='toggle'></span>
        {h3{#(title)}}
        {{> @chevron}}
        {{> @activateButton}}
      </div>
    """
