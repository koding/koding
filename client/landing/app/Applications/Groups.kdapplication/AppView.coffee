class GroupsComingSoon extends KDView
  viewAppended:()->
    @setClass "coming-soon-page"
    @setPartial @partial

  partial:()->
    partial = $ """
      <div class='comingsoon'>
        <img src='../images/topicsbig.png' alt='Groups are coming soon!'><h1>Koding Groups</h1>
        <h2>Coming soon</h2>
      </div>
    """

class GroupsMainView extends KDView

  constructor:(options,data)->
    options = $.extend
      ownScrollBars : yes
    ,options
    super options,data

  createCommons:->
    @addSubView header = new HeaderViewSection type : "big", title : "Groups"
    header.setSearchInput()
    # @addSubView new CommonFeedMessage
    #   title           : "<p>Topic tags organize shared content on Koding. Tag items when you share, and follow topics to see content relevant to you in your activity feed.</p>"
    #   messageLocation : 'Topics'

  createTopicsHint:->
    listController.scrollView.addSubView notice = new KDCustomHTMLView
      cssClass  : "groups-hint"
      tagName   : "p"
      partial   : "<span class='icon'></span>"

    @listenTo
      KDEventTypes : "click"
      listenedToInstance : notice
      callback : (pubInst,event)->
        if $(event.target).is "a.closeme"
          notice.$().animate marginTop : "-16px", opacity : 0.001,150,()->notice.destroy()

  # addAddTopicButton:->
  #   new KDButtonView
  #     title     : "Add Topic"
  #     style     : "small-gray"
  #     callback  : ->
  #       modal = new KDModalViewWithForms
  #         title                   : "Add a Topic"
  #         content                 : ""
  #         overlay                 : yes
  #         width                   : 500
  #         height                  : "auto"
  #         cssClass                : "new-kdmodal"
  #         tabs                    :
  #           callback          : (formData,event)->
  #             mainView.emit "AddATopicFormSubmitted",formData
  #           forms                 :
  #             "Add a topic"       :
  #               fields            :
  #                 Name            :
  #                   type          : "text"
  #                   name          : "title"
  #                   placeholder   : "give a name to your topic..."
  #                   validate      :
  #                     rules       :
  #                       required  : yes
  #                     messages    :
  #                       required  : "Topic name is required!"
  #                 Description     :
  #                   type          : "textarea"
  #                   name          : "body"
  #                   placeholder   : "and give topic a description..."
  #               buttons           :
  #                 Add             :
  #                   style         : "modal-clean-gray"
  #                   type          : 'submit'
  #                 Cancel          :
  #                   style         : "modal-cancel"
  #                   callback      : ()-> modal.destroy()
