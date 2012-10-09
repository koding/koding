class DashboardPane extends Pane

  constructor:->

    super

    @listController = new KDListViewController
      lastToFirst     : yes
      viewOptions     :
        type          : "wp-blog"
        itemClass  : InstalledAppListItem

    @listWrapper = @listController.getView()

    @notice = new KDCustomHTMLView
      tagName : "p"
      cssClass: "why-u-no"
      partial : "Why u no create wordpress!!!"

    @notice.hide()

    @listController.getListView().on "DeleteLinkClicked", (listItemView)=>

      @removeItem listItemView
      {path, domain, name} = listItemView.getData()
      command = "rm -r '/Users/#{nickname}/Sites/#{domain}/website/#{path}'"
      parseOutput "<br><br>Deleting /Users/#{nickname}/Sites/#{domain}/website/#{path}<br><br>"
      parseOutput command
      kc.run withArgs  : {command} , (err, res)=>
        if err
          parseOutput err, yes
          new KDNotificationView
            title    : "There was an error, you may need to remove it manually!"
            duration : 3333
        else
          parseOutput "<br><br>#############"
          parseOutput "<br>#{name} successfully deleted."
          parseOutput "<br>#############<br><br>"
          tc.refreshFolder tc.nodes["/Users/#{nickname}/Sites/#{domain}/website"]

        __utils.wait 1500, ->
          split.resizePanel 0, 1

  removeItem:(listItemView)->

    @listController.removeItem listItemView
    appStorage.fetchStorage (storage)=>
      blogs = appStorage.getValue("blogs") or []
      @notice.show() if blogs.length is 0


  putNewItem:(formData, resizeSplit = yes)->

    tabs = @getDelegate()
    tabs.showPane @
    @listController.addItem formData
    @notice.hide()
    if resizeSplit
      __utils.wait 1500, -> split.resizePanel 0, 1

  viewAppended:->

    super

    appStorage.fetchStorage (storage)=>
      blogs = appStorage.getValue("blogs") or []
      if blogs.length > 0
        blogs.sort (a, b) -> if a.timestamp < b.timestamp then -1 else 1
        blogs.forEach (item)=> @putNewItem item, no
      else
        @notice.show()

  pistachio:->
    """
    {{> @notice}}
    {{> @listWrapper}}
    """

class InstalledAppListItem extends KDListItemView

  constructor:(options, data)->

    options.type = "wp-blog"

    super options, data

    @delete = new KDCustomHTMLView
      tagName : "a"
      cssClass: "delete-link"
      click   : (pubInst, event)=>
        split.resizePanel 250, 0
        blogs = appStorage.getValue "blogs"
        blogs.splice blogs.indexOf(@getData()), 1
        appStorage.setValue "blogs", blogs, =>
          @getDelegate().emit "DeleteLinkClicked", @

  viewAppended:->

    @setTemplate @pistachio()
    @template.update()
    @utils.wait => @setClass "in"

  pistachio:->
    {path, timestamp, domain, name} = @getData()
    url = "http://#{domain}/#{path}"
    """
    {{> @delete}}
    <a target='_blank' class='name-link' href='#{url}'>{{ #(name)}}</a>
    <a target='_blank' class='admin-link' href='#{url}#{if path is "" then '' else '/'}wp-admin'>Admin</a>
    <a target='_blank' class='raw-link' href='#{url}'>#{url}</a>
    <time datetime='#{new Date(timestamp)}'>#{$.timeago new Date(timestamp)}</time>
    """

