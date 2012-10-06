class EnvironmentViewTopProcesses extends KDView
  __getTime = ->
    a = new Date()
    "#{a.getHours()}:#{a.getMinutes()}:#{a.getSeconds()}"
  __getNumber = __utils.getRandomNumber

  viewAppended:->
    @setHeight "auto"
    @setClass "process-stats"

    @addSubView subHeader = new KDHeaderView type:"small",title:"Top Processes"
    @addSubView listHeader = new KDView cssClass:"process-list-header"

    for column,value of @usageData[0]
      listHeader.setPartial "<span class='cell'>#{column}</span>"

    @addSubView list = new EnvironmentTopProcessesList itemClass : EnvironmentTopProcessesListItem,cssClass:"process-list",(items : @usageData)

  usageData :[
      { pid : __getNumber(65536), command : "node",     time : __getTime(), rsize : "#{__getNumber(48)}M", port : __getNumber(4800), cpu : 40.4 }
      { pid : __getNumber(65536), command : "mysql",    time : __getTime(), rsize : "#{__getNumber(48)}M", port : __getNumber(4800), cpu : 23.8 }
      { pid : __getNumber(65536), command : "kodingd",  time : __getTime(), rsize : "#{__getNumber(48)}M", port : __getNumber(4800), cpu : 23.5 }
      { pid : __getNumber(65536), command : "dropbox",  time : __getTime(), rsize : "#{__getNumber(48)}M", port : __getNumber(4800), cpu : 12.8 }
      { pid : __getNumber(65536), command : "php",      time : __getTime(), rsize : "#{__getNumber(48)}M", port : __getNumber(4800), cpu : 6.8 }
      { pid : __getNumber(65536), command : "nginx",    time : __getTime(), rsize : "#{__getNumber(48)}M", port : __getNumber(4800), cpu : 3.4 }
    ]

class EnvironmentTopProcessesList extends KDListView
  setDomElement:(cssClass)->
    @domElement = $ "<ul class='kdview #{cssClass}'></ul>"

class EnvironmentTopProcessesListItem extends KDListItemView
  setDomElement:(cssClass)->
    @domElement = $ "<li class='kdview kdlistview #{cssClass}'></li>"

  viewAppended:->
    super
    @$(".cpu-load-progress").width "#{@getData().cpu}%"

  partial:(data)->
    """
    <div class='cpu-load-progress'></div>
    <div class='cell first'>#{data.pid}</div>
    <div class='cell'>#{data.command}</div>
    <div class='cell'>#{data.time}</div>
    <div class='cell'>#{data.rsize}</div>
    <div class='cell'>#{data.port}</div>
    <div class='cell'>#{data.cpu}</div>
    """
