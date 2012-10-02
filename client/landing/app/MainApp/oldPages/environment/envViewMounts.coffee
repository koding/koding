class EnvironmentViewMounts extends KDView
  __getTime = ->
    a = new Date()
    "#{a.getHours()}:#{a.getMinutes()}:#{a.getSeconds()}"
  __getNumber = __utils.getRandomNumber

  viewAppended:->
    @setHeight "auto"
    @setClass "mounts-stats"

    @addSubView subHeader = new KDHeaderView type:"small",title:"My Mounts"
    @addSubView list = new EnvironmentMountsList itemClass : EnvironmentMountsListItem,cssClass:"process-list",(items : @usageData)

  usageData :[
      { type : "ftp", host : "blahblah.com",     status: "active" }
      { type : "ftp", host : "bazil.com",        status: "active" }
      { type : "ssh", host : "127.987.12.423",   status: "connection-problem" }
    ]

class EnvironmentMountsList extends KDListView
  setDomElement:(cssClass)->
    @domElement = $ "<ul class='kdview #{cssClass}'></ul>"

class EnvironmentMountsListItem extends KDListItemView
  setDomElement:(cssClass)->
    @domElement = $ "<li class='kdview kdlistview #{cssClass}'></li>"

  partial:(data)->
    """
      <div class='status-#{data.status}'>
        <span class='icon'></span>
        <label>#{data.host}</label>
        <span class='tag'>#{data.type}</span>
        <a href="#" class='action-link type-#{data.type}'>Edit</a>
      </div>
    """