class EnvironmentViewUsage extends KDView
  viewAppended:->
    @setHeight "auto"
    @setClass "usage-stats"

    @addSubView subHeader = new KDHeaderView type:"small",title:"Usage"
    subHeader.addSubView addResourcesButton = new KDButtonView
      style     : "add-item-btn"
      title     : "Add Resources"
      icon      : yes
      iconClass : "resources"
      callback  : ()-> log "Add Resources!"
    @addSubView list = new EnvironmentUsageList itemClass : EnvironmentUsageListItem,(items : @usageData)

  usageData :[
      { title : "storage", used  : 100,total : 100,unit  : "MB" }
      { title : "memory", used  : 90,total : 100,unit  : "MB" }
      { title : "transfer", used  : 80,total : 100,unit  : "GB" }
      { title : "CPU", used  : 70,total : 100,totalText : "1 Core",unit  : "%" }
      { title : "storage", used  : 60,total : 100,unit  : "MB" }
      { title : "memory", used  : 50,total : 100,unit  : "MB" }
      { title : "transfer", used  : 40,total : 100,unit  : "GB" }
      { title : "CPU", used  : 30,total : 100,totalText : "1 Core",unit  : "%" }
      { title : "storage", used  : 20,total : 100,unit  : "MB" }
      { title : "memory", used  : 10,total : 100,unit  : "MB" }
      # { title : "memory", used  : 24,total : 128,unit  : "MB" }
      # { title : "storage", used  : 240,total : 500,unit  : "MB" }
      # { title : "CPU", used  : 64,total : 100,totalText : "1 Core",unit  : "%" }
      # { title : "transfer", used  : 82,total : 250,unit  : "GB" }
    ]

class EnvironmentUsageList extends KDListView
  setDomElement:(cssClass)->
    @domElement = $ "<ul class='kdview #{cssClass}'></ul>"

class EnvironmentUsageListItem extends KDListItemView
  colors : [ "#FFD666", "#FFCB52", "#FFC042", "#FFB433", "#FFA024", "#FF8E14", "#FF7C0A", "#FF6A00", "#F05800", "#E64900" ]

  setDomElement:(cssClass)->
    @domElement = $ "<li class='kdview kdlistview #{cssClass}'></li>"

  viewAppended:->
    super
    window.xx = @
    total = @getData().total
    used = @getData().used
    calcWidth = used/total*100
    color = @colors[Math.round(calcWidth/10)-1]

    log @colors,color,used

    setTimeout ()=>

      @$(".bar").animate
        width : "#{calcWidth}%"
        backgroundColor : color
      ,
        duration      : 800
        specialEasing :
          width           : 'easeInQuart'
          backgroundColor : 'linear'
        complete      : ()-> noop

    ,500

  partial:(data)->
    """
    <label>#{data.title} <span></span></label>

    <div class='stats'>
      <span class='stat'>#{data.used} #{data.unit}</span>
      <span class='total'>#{data.totalText or data.total + data.unit}</span>
      <div class='bar'><div class='pattern'></div></div>
    </div>
    """










