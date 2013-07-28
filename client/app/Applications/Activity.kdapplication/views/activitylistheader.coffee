class ActivityListHeader extends JView

  __count = 0


  constructor:->

    super

    @appStorage = new AppStorage 'Activity', '1.0'
    @_newItemsCount = 0

    @showNewItemsInTitle = no

    @showNewItemsLink = new KDCustomHTMLView
      cssClass    : "new-updates"
      partial     : "<span>0</span> new items. <a href='#' title='Show new activities'>Update</a>"
      click       : =>
        @updateShowNewItemsLink yes


    @headerTitle = new KDCustomHTMLView
      partial     : "Latest Activity"
      tagName: "span"

    @showNewItemsLink.hide()

    @liveUpdateButton = new KDOnOffSwitch
      defaultValue : off
      title        : "Live Updates: "
      size         : "tiny"
      callback     : (state) =>
        @_togglePollForUpdates state
        @appStorage.setValue 'liveUpdates', state, ->
        @updateShowNewItemsLink()
        KD.getSingleton('activityController').flags = liveUpdates : state
        KD.getSingleton('activityController').emit "LiveStatusUpdateStateChanged", state


    @downloadOldKodingFilesLink = new KDView
      cssClass : "download-old-koding-files"
      partial  : ''
      click    : (event)=>
        @downloadOldKodingFiles()

    KD.getSingleton('mainController').on 'AccountChanged', ()=>
      @decorateLiveUpdateButton()
      @decorateDownloadOldFilesLink()


    @decorateLiveUpdateButton()
    @decorateDownloadOldFilesLink()

    if KD.checkFlag "super-admin"
      @lowQualitySwitch = new KDOnOffSwitch
        defaultValue : off
        title        : "Show trolls: "
        size         : "tiny"
        callback     : (state) =>
          @appStorage.setValue 'showLowQualityContent', state, =>

      @refreshLink = new KDCustomHTMLView
        tagName  : 'a'
        cssClass : 'fr'
        partial  : 'Refresh'
        click    : (event)=>
          KD.getSingleton('activityController').emit 'Refresh'

    else
      @lowQualitySwitch = new KDCustomHTMLView
      @refreshLink      = new KDCustomHTMLView
        tagName: "span"

    @appStorage.fetchStorage (storage)=>
      state = @appStorage.getValue('liveUpdates') or off
      @liveUpdateButton.setValue state
      KD.getSingleton('activityController').flags = liveUpdates : state
      @lowQualitySwitch.setValue? @appStorage.getValue('showLowQualityContent') or off

  downloadOldKodingFiles:()->
    KD.whoami().fetchOldKodingDownloadLink (err, url)=>
      if err then return @dislayDonloadLinkModal("Something went wrong", err.message)

      # check if user has default vm
      vmController = KD.getSingleton("vmController")
      vmController.fetchVMs yes, (err, vms)=>
        if err then return @dislayDonloadLinkModal("Something went wrong", err.message)
        #display VM not found error
        if vms.length < 1
          @dislayDonloadLinkModal("You don't have any VM", "You don't have any VMs to save the files, please create a VM and then try again.")
        else
          @showProcessStartedMessageForDownload(vms)
          #prepare command
          fileName = url.split("/").last
          folderName = "old.koding.com-backup-#{Date.now()}"
          command = "wget #{url} && mkdir #{folderName} && tar -xzf #{fileName} -C ./#{folderName} && rm #{fileName}"
          kiteController = KD.getSingleton "kiteController"
          kiteController.run command, (err, res) =>
            if err then return @showDownloadFailedMessage(vms)

            return @showDownloadFinishedMessage(vms, folderName)

  showProcessStartedMessageForDownload:(vms)->
    message =
      """
      We started to fecth your old files.<br/><br/>
      Your old files will be saved to <br/>
      <strong>/home/#{KD.whoami().profile.nickname}/ </strong> folder in <br/>
      your <strong>#{vms.first} VM </strong><br/>
      You can continue to browse<br/>
      """

    @dislayDonloadLinkModal("Process Started", message)

  showDownloadFailedMessage:(vms)->
    message = """
      We couldn't fetch your files from old.koding.com.<br/>
      This can happen when;<br/>
      You dont have any files at old.koding.com<br/>
      You don't have any left space on your VM.<br/>
      Please check for the possible causing problems and try again.<br/>
    """
    @dislayDonloadLinkModal("Process Failed", message)


  showDownloadFinishedMessage:(vms, folderName)->
    message =
      """
      We successfuly saved your old files.<br/><br/>
      Your old files are at your <br/>
      <strong>#{vms.first} VM </strong> and in<br/>
      <strong>/home/#{KD.whoami().profile.nickname}/#{folderName} </strong> folder<br/>
      """

    @dislayDonloadLinkModal("Process Finished", message)

  decorateDownloadOldFilesLink:()->
    partial = ""
    if KD.isLoggedIn()
      @appStorage.fetchValue 'showOldKodingDataDownloadLink', (status)=>
        if not status? or status isnt "false"
          partial = "Download Old Koding.com Files"
          @downloadOldKodingFilesLink.updatePartial partial
    @downloadOldKodingFilesLink.updatePartial partial

  disableShowingDownloadLink:()->
    # bool false is not working
    @appStorage.setValue 'showOldKodingDataDownloadLink', "false"

  dislayDonloadLinkModal: (title, message)->
    @modal?.destroy()
    @modal = modal = new KDModalView
      title        : title
      overlay      : yes
      content      : """
                      <div class='modalformline'>
                        #{message}
                      </div>
                    """
      buttons :
        "Close" :
          style     : "modal-clean-red"
          callback  : ->
            modal.destroy()
        "Do not show me download link again" :
          style     : "modal-clean-green"
          callback  : =>
            @downloadOldKodingFilesLink.updatePartial ""
            @disableShowingDownloadLink()
            @modal.destroy()


  _checkForUpdates: do (lastTs = null, lastCount = null) ->
    itFailed = ->
      console.warn 'seems like live updates stopped coming'
      KD.logToExternal 'realtime failure detected'
    ->
      KD.remote.api.CActivity.fetchLastActivityTimestamp (err, ts) =>
        itFailed()  if ts? and lastTs isnt ts and lastCount is __count
        lastTs = ts; lastCount = __count

  _togglePollForUpdates: do (i = null) -> (state) ->
    if state then i = setInterval (@bound '_checkForUpdates'), 60 * 1000 # 1 minute
    else clearInterval i

  pistachio:(newCount)->
    "<div class='header-wrapper'>{{> @headerTitle}} {{> @downloadOldKodingFilesLink }} {{> @lowQualitySwitch}} {{> @liveUpdateButton}} {{> @showNewItemsLink}}{{> @refreshLink}}</div>"

  newActivityArrived:->
    __count++
    @_newItemsCount++
    @updateShowNewItemsLink()
    @updateShowNewItemsTitle()  if @showNewItemsInTitle

  decorateLiveUpdateButton:->
    @liveUpdateButton.show()
    # if KD.isLoggedIn() then @liveUpdateButton.show()
    # else @liveUpdateButton.hide()

  updateShowNewItemsLink:(showNewItems = no)->
    if @_newItemsCount > 0
      if @liveUpdateButton.getValue() is yes or showNewItems is yes
        @emit "UnhideHiddenNewItems"
        @_newItemsCount = 0
        @showNewItemsLink.hide()
      else
        @showNewItemsLink.$('span').text @_newItemsCount
        @showNewItemsLink.show()
    else
      @showNewItemsLink.hide()

  updateShowNewItemsTitle: ->
    if @_newItemsCount > 0
      document.title = "(#{@_newItemsCount}) Activity"
    else
      @hideDocumentTitleCount()

  hideDocumentTitleCount: ->
    document.title = "Activity"

  getNewItemsCount: ->
    return @_newItemsCount
