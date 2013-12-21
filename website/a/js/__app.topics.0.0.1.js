var TopicsAppController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
TopicsAppController=function(_super){function TopicsAppController(options,data){null==options&&(options={})
options.view=new TopicsMainView({cssClass:"content-page topics"})
options.appInfo={name:"Topics"}
TopicsAppController.__super__.constructor.call(this,options,data)
this.listItemClass=TopicsListItemView
this.controllers={}}__extends(TopicsAppController,_super)
KD.registerAppClass(TopicsAppController,{name:"Topics",route:"/:name?/Topics",hiddenHandle:!0})
TopicsAppController.prototype.createFeed=function(view,loadFeed){var JTag,_this=this
null==loadFeed&&(loadFeed=!1)
JTag=KD.remote.api.JTag
return KD.getSingleton("appManager").tell("Feeder","createContentFeedController",{feedId:"topics.main",itemClass:this.listItemClass,limitPerPage:20,useHeaderNav:!0,delegate:this,noItemFoundText:"There are no topics.",help:{subtitle:"Learn About Topics",tooltip:{title:'<p class="bigtwipsy">Topic Tags organize content that users share on Koding. Follow the topics you are interested in and we\'ll include the tagged items in your activity feed.</p>',placement:"above"}},filter:{everything:{title:"All topics",optional_title:this._searchValue?"<span class='optional_title'></span>":null,dataSource:function(selector,options,callback){if(_this._searchValue){_this.setCurrentViewHeader("Searching for <strong>"+_this._searchValue+"</strong>...")
return JTag.byRelevance(_this._searchValue,options,callback)}return JTag.streamModels(selector,options,callback)},dataError:function(){return log("Seems something broken:",arguments)}},following:{loggedInOnly:!0,title:"Following",noItemFoundText:"There are no topics that you follow.",dataSource:function(selector,options,callback){return KD.whoami().fetchTopics(selector,options,function(err,items){var ids,item,_i,_len
ids=[]
for(_i=0,_len=items.length;_len>_i;_i++){item=items[_i]
item.followee=!0
ids.push(item._id)}callback(err,items)
return err?void 0:callback(null,null,ids)})}}},sort:{"counts.followers":{title:"Most popular",direction:-1},"meta.modifiedAt":{title:"Latest activity",direction:-1},"counts.post":{title:"Most activity",direction:-1}}},function(controller){_this.feedController=controller
view.addSubView(_this._lastSubview=controller.getView())
controller.on("FeederListViewItemCountChanged",function(count){return _this._searchValue?_this.setCurrentViewHeader(count):void 0})
loadFeed&&controller.loadFeed()
_this.emit("ready")
return KD.mixpanel("Loaded topic list")})}
TopicsAppController.prototype.loadView=function(mainView,firstRun,loadFeed){var _this=this
null==firstRun&&(firstRun=!0)
null==loadFeed&&(loadFeed=!1)
if(firstRun){mainView.on("searchFilterChanged",function(value){var _base
if(value!==_this._searchValue){_this._searchValue=Encoder.XSSEncode(value)
"function"==typeof(_base=_this._lastSubview).destroy&&_base.destroy()
return _this.loadView(mainView,!1,!0)}})
mainView.createCommons()}if(KD.checkFlag(["super-admin","editor"])){this.listItemClass=TopicsListItemViewEditable
firstRun&&KD.getSingleton("mainController").on("TopicItemEditLinkClicked",function(topicItem){return _this.updateTopic(topicItem)})}return this.createFeed(mainView,loadFeed)}
TopicsAppController.prototype.openTopic=function(topic){var entryPoint
entryPoint=KD.config.entryPoint
return KD.getSingleton("router").handleRoute("/Topics/"+topic.slug,{state:topic,entryPoint:entryPoint})}
TopicsAppController.prototype.updateTopic=function(topicItem){var controller,modal,topic,_this=this
topic=topicItem.data
controller=this
return modal=new KDModalViewWithForms({title:"Update topic "+topic.title,height:"auto",cssClass:"compose-message-modal",width:779,overlay:!0,tabs:{navigable:!0,goToNextFormOnSubmit:!1,forms:{update:{title:"Update Topic Details",callback:function(formData){formData.slug=_this.utils.slugify(formData.slug.trim().toLowerCase())
return topic.modify(formData,function(err){new KDNotificationView({title:err?err.message:"Updated successfully"})
return modal.destroy()})},buttons:{Update:{style:"modal-clean-gray",type:"submit",loader:{color:"#444444",diameter:12}},Delete:{style:"modal-clean-red",loader:{color:"#ffffff",diameter:16},callback:function(){return topic["delete"](function(err){modal.destroy()
new KDNotificationView({title:err?err.message:"Deleted!"})
return err?void 0:topicItem.hide()})}}},fields:{Title:{label:"Title",itemClass:KDInputView,name:"title",defaultValue:topic.title},Slug:{label:"Slug",itemClass:KDInputView,name:"slug",defaultValue:topic.slug},Details:{label:"Details",type:"textarea",itemClass:KDInputView,name:"body",defaultValue:topic.body||""}}}}}})}
TopicsAppController.prototype.fetchSomeTopics=function(options,callback){var selector
null==options&&(options={})
options.limit||(options.limit=6)
options.skip||(options.skip=0)
options.sort||(options.sort={"counts.followers":-1})
selector=options.selector
options.selector&&delete options.selector
return selector?KD.remote.api.JTag.byRelevance(selector,options,callback):KD.remote.api.JTag.some({},options,callback)}
TopicsAppController.prototype.setCurrentViewHeader=function(count){var result,title
if("number"!=typeof count){this.getView().$(".feeder-header span.optional_title").html(count)
return!1}count>=20&&(count="20+")
0===count&&(count="No")
result=""+count+" result"+(1!==count?"s":"")
title=""+result+" found for <strong>"+this._searchValue+"</strong>"
return this.getView().$(".feeder-header").html(title)}
TopicsAppController.prototype.createContentDisplay=function(topic,callback){var contentDisplay,controller
controller=new ContentDisplayControllerTopic(null,topic)
contentDisplay=controller.getView()
contentDisplay.on("handleQuery",function(query){return controller.ready(function(){var _ref
return null!=(_ref=controller.feedController)?"function"==typeof _ref.handleQuery?_ref.handleQuery(query):void 0:void 0})})
this.showContentDisplay(contentDisplay)
return this.utils.defer(function(){return callback(contentDisplay)})}
TopicsAppController.prototype.showContentDisplay=function(contentDisplay){return KD.singleton("display").emit("ContentDisplayWantsToBeShown",contentDisplay)}
TopicsAppController.prototype.fetchTopics=function(_arg,callback){var blacklist,inputValue
inputValue=_arg.inputValue,blacklist=_arg.blacklist
return KD.remote.api.JTag.byRelevance(inputValue,{blacklist:blacklist},function(err,tags){return err?warn("there was an error fetching topics "+err.message):"function"==typeof callback?callback(tags):void 0})}
return TopicsAppController}(AppController)

var TopicsMainView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__indexOf=[].indexOf||function(item){for(var i=0,l=this.length;l>i;i++)if(i in this&&this[i]===item)return i
return-1}
TopicsMainView=function(_super){function TopicsMainView(options,data){null==options&&(options={})
null==options.ownScrollBars&&(options.ownScrollBars=!0)
TopicsMainView.__super__.constructor.call(this,options,data)}__extends(TopicsMainView,_super)
TopicsMainView.prototype.createCommons=function(){this.addSubView(this.header=new HeaderViewSection)
KD.getSingleton("mainController").on("AccountChanged",this.bound("setSearchInput"))
return this.setSearchInput()}
TopicsMainView.prototype.setSearchInput=function(){return __indexOf.call(KD.config.permissions,"read tags")>=0?this.header.setSearchInput():void 0}
return TopicsMainView}(KDView)

var ModalTopicsListItem,TopicsListItemView,TopicsListItemViewEditable,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
TopicsListItemView=function(_super){function TopicsListItemView(options,data){var _this=this
null==options&&(options={})
options.type="topics"
TopicsListItemView.__super__.constructor.call(this,options,data)
this.titleLink=new KDCustomHTMLView({tagName:"a",pistachio:"{{#(title)}}",click:function(event){KD.singletons.router.handleRoute("/Activity?tagged="+data.slug)
return KD.utils.stopDOMEvent(event)}},data)
this.editButton=options.editable?new KDCustomHTMLView({tagName:"a",cssClass:"edit-topic",pistachio:'<span class="icon"></span>Edit',click:function(){return KD.getSingleton("mainController").emit("TopicItemEditLinkClicked",_this)}},null):new KDCustomHTMLView({tagName:"span",cssClass:"hidden"})
this.followButton=new FollowButton({cssClass:"solid green",errorMessages:{KodingError:"Something went wrong while follow",AccessDenied:"You are not allowed to follow topics"},stateOptions:{unfollow:{cssClass:"following-btn"}},dataType:"JTag"},data)}__extends(TopicsListItemView,_super)
TopicsListItemView.prototype.titleReceivedClick=function(){return this.emit("LinkClicked")}
TopicsListItemView.prototype.viewAppended=function(){this.setClass("topic-item")
this.setTemplate(this.pistachio())
return this.template.update()}
TopicsListItemView.prototype.setFollowerCount=function(count){return this.$(".followers a").html(count)}
TopicsListItemView.prototype.expandItem=function(){var $clone,$item,$parent,list,pos,_this=this
if(this._trimmedBody){list=this.getDelegate()
$item=this.$()
$parent=list.$()
this.$clone=$clone=$item.clone()
pos=$item.position()
pos.height=$item.outerHeight(!1)
$clone.addClass("clone")
$clone.css(pos)
$clone.css({"background-color":"white"})
$clone.find(".topictext article").html(this.getData().body)
$parent.append($clone)
$clone.addClass("expand")
return $clone.on("mouseleave",function(){return _this.collapseItem()})}}
TopicsListItemView.prototype.collapseItem=function(){!this._trimmedBody}
TopicsListItemView.prototype.pistachio=function(){return'{{> this.editButton}}\n<header>\n  {h3{> this.titleLink}}\n</header>\n<div class="stats">\n  <a href="#">{{#(counts.post) || 0}}</a> Posts\n  <a href="#">{{#(counts.followers) || 0}}</a> Followers\n</div>\n{article{#(body)}}\n{{> this.followButton}}'}
return TopicsListItemView}(KDListItemView)
ModalTopicsListItem=function(_super){function ModalTopicsListItem(options,data){var _this=this
ModalTopicsListItem.__super__.constructor.call(this,options,data)
this.titleLink=new TagLinkView({expandable:!1,click:function(){return _this.getDelegate().emit("CloseTopicsModal")}},data)}__extends(ModalTopicsListItem,_super)
ModalTopicsListItem.prototype.pistachio=function(){return'<div class="topictext">\n  <div class="topicmeta">\n    <div class="button-container">{{> this.followButton}}</div>\n    {{> this.titleLink}}\n    <div class="stats">\n      <p class="posts">\n        <span class="icon"></span>{{#(counts.post) || 0}} Posts\n      </p>\n      <p class="fers">\n        <span class="icon"></span>{{#(counts.followers) || 0}} Followers\n      </p>\n    </div>\n  </div>\n</div>'}
return ModalTopicsListItem}(TopicsListItemView)
TopicsListItemViewEditable=function(_super){function TopicsListItemViewEditable(options,data){null==options&&(options={})
options.editable=!0
options.type="topics"
TopicsListItemViewEditable.__super__.constructor.call(this,options,data)}__extends(TopicsListItemViewEditable,_super)
return TopicsListItemViewEditable}(TopicsListItemView)

var ContentDisplayControllerTopic,TopicView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ContentDisplayControllerTopic=function(_super){function ContentDisplayControllerTopic(options,data){var mainView
null==options&&(options={})
options.view=mainView=new KDView({cssClass:"topic content-display"})
ContentDisplayControllerTopic.__super__.constructor.call(this,options,data)}__extends(ContentDisplayControllerTopic,_super)
ContentDisplayControllerTopic.prototype.loadView=function(mainView){var backLink,subHeader,topic,topicView,_this=this
topic=this.getData()
mainView.addSubView(subHeader=new KDCustomHTMLView({tagName:"h2",cssClass:"sub-header"}))
backLink=new KDCustomHTMLView({tagName:"a",partial:"<span>&laquo;</span> Back",click:function(event){event.stopPropagation()
event.preventDefault()
return KD.singleton("display").emit("ContentDisplayWantsToBeHidden",mainView)}})
KD.isLoggedIn()&&subHeader.addSubView(backLink)
topicView=this.addTopicView(topic)
return KD.getSingleton("appManager").tell("Feeder","createContentFeedController",{feedId:"topics."+topic.slug,itemClass:ActivityListItemView,listCssClass:"activity-related",noItemFoundText:"There is no activity related with <strong>"+topic.title+"</strong>.",limitPerPage:5,filter:{content:{title:"Everything",dataSource:function(selector,options,callback){return topic.fetchContentTeasers(options,function(err,teasers){return callback(err,teasers)})}},statusupdates:{title:"Status Updates",dataSource:function(selector,options,callback){selector={targetName:"JNewStatusUpdate"}
return topic.fetchContentTeasers(options,selector,function(err,teasers){return callback(err,teasers)})}},codesnippets:{title:"Code Snippets",dataSource:function(selector,options,callback){selector={targetName:"JCodeSnip"}
return topic.fetchContentTeasers(options,selector,function(err,teasers){return callback(err,teasers)})}}},sort:{"timestamp|new":{title:"Latest activity",direction:-1},"timestamp|old":{title:"Most activity",direction:1}}},function(controller){_this.feedController=controller
mainView.addSubView(controller.getView())
return _this.emit("ready")})}
ContentDisplayControllerTopic.prototype.addTopicView=function(topic){var topicContentDisplay,topicView
topicContentDisplay=this.getView()
topicContentDisplay.addSubView(topicView=new TopicView({cssClass:"profilearea clearfix",delegate:topicContentDisplay},topic))
return topicView}
return ContentDisplayControllerTopic}(KDViewController)
TopicView=function(_super){function TopicView(options,data){this.followButton=new FollowButton({errorMessages:{KodingError:"Something went wrong while follow",AccessDenied:"You are not allowed to follow topics"},stateOptions:{unfollow:{cssClass:"following-topic"}},dataType:"JTag"},data)
TopicView.__super__.constructor.apply(this,arguments)}__extends(TopicView,_super)
TopicView.prototype.pistachio=function(){return"<div class=\"profileleft\">\n  <span>\n    <a class='profile-avatar' href='#'>{{#(image) || \"upload an image\"}}</a>\n  </span>\n  {{> this.followButton}}\n</div>\n\n<section>\n  <div class=\"profileinfo\">\n    {h3{#(title)}}\n\n    <div class=\"profilestats\">\n      <div class=\"posts\">\n        <a href='#'><cite/>{{this.utils.formatPlural(#(counts.post), 'Post')}}</a>\n      </div>\n      <div class=\"fers\">\n        <a href='#'><cite/>{{this.utils.formatPlural(#(counts.followers), 'Follower')}}</a>\n      </div>\n    </div>\n  </div>\n\n  <div class='profilebio'>\n    {p{#(body)}}\n  </div>\n\n  <div class=\"skilltags\">\n  </div>\n\n</section>"}
return TopicView}(JView)

var TopicSplitViewController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
TopicSplitViewController=function(_super){function TopicSplitViewController(options,data){null==options&&(options={})
options=$.extend({view:new ContentPageSplitBelowHeader({sizes:[139,null],minimums:[10,null],resizable:!1})},options)
TopicSplitViewController.__super__.constructor.call(this,options,data)}__extends(TopicSplitViewController,_super)
TopicSplitViewController.prototype.loadView=function(topicSplit){log(topicSplit)
return topicSplit._windowDidResize()}
return TopicSplitViewController}(KDViewController)

//@ sourceMappingURL=/js/__app.topics.0.0.1.js.map