class JobsView extends KDView
  constructor : (options = {}) ->
    options.cssClass = KD.utils.curry 'jobs-view', options.cssClass
    options.apiUrl   = "#{KD.apiUri}/-/jobs"

    super options

    @loader = new KDLoaderView
      size      :
        width   : 30
        height  : 30

      showLoader: yes

    @addSubView @loader

    @getJobs()

  getJobs : ->
    $.ajax
      url     : @getOption 'apiUrl'
      timeOut : 5000
      success : @bound 'createView'
      error   : @bound 'fetchError'

  fetchError : (error) ->
    error error

  createView : (data) ->

    for jobData, index in data
      delay = 0.3 * index

      @addSubView jobView = new JobsItemView
        attributes :
          style    : "-webkit-transition-delay: #{delay}s; -moz-transition-delay: #{delay}s;"
      , jobData

    KD.utils.wait 100, => @setClass 'animate'
    @loader.destroy()




