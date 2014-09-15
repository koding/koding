module.exports = class JobsView extends KDView
  constructor : (options = {}) ->

    options.cssClass = KD.utils.curry 'jobs-view', options.cssClass
    options.apiUrl   = "#{KD.apiUri or window.location.origin}/-/jobs"

    super options

    @loader = new KDLoaderView
      size      :
        width   : 30
        height  : 30
      showLoader: yes

    @getJobs()


  getJobs : ->

    if @errorView then @errorView.destroy()

    @addSubView @loader

    $.ajax
      url     : @getOption 'apiUrl'
      timeOut : 5000
      success : @bound 'createView'
      error   : @bound 'showError'


  showError : (data) ->

    @loader.destroy()

    @addSubView @errorView = new KDCustomHTMLView
      partial   : "Couldn't fetch job openings, please "
      cssClass  : "jobs-error"

    @errorView.addSubView new CustomLinkView
      cssClass   : 'retry-link'
      title      : 'try again'
      click      : @bound 'getJobs'


  createView : (data) ->

    for jobData, index in data
      @addSubView jobView = new JobsItemView {}, jobData

    KD.utils.wait 100, => @setClass 'animate'
    @loader.destroy()




