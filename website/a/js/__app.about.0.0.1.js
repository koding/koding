KD.extend({team:{active:[{username:"devrim",title:"Co-Founder &amp; CEO"},{username:"sinan",title:"Co-Founder &amp; Chief UI Engineer"},{username:"chris",title:"Director of Engineering"},{username:"gokmen",title:"Software Engineer"},{username:"arslan",title:"Software Engineer"},{username:"fatihacet",title:"Front-End Developer"},{username:"sent-hil",title:"Software Engineer"},{username:"cihangirsavas",title:"Software Engineer"},{username:"geraint",title:"System Administrator"},{username:"ybrs",title:"Software Engineer"},{username:"erdinc",title:"Software Engineer"},{username:"szkl",title:"Software Engineer"},{username:"samet",title:"Software Engineer"},{username:"cenk6",title:"Software Engineer"},{username:"burakcan",title:"CSS Wizard"},{username:"emred",title:"Designer"},{username:"canthefason",title:"Software Engineer"},{username:"pablostanley",title:"Illustrator"}],suspended:[]}})

var AboutAppController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
AboutAppController=function(_super){function AboutAppController(options,data){null==options&&(options={})
options.view=new AboutView({cssClass:"content-page about"})
AboutAppController.__super__.constructor.call(this,options,data)}__extends(AboutAppController,_super)
KD.registerAppClass(AboutAppController,{name:"About",route:"/About"})
return AboutAppController}(AppController)

var AboutListItem,AboutView,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
AboutView=function(_super){function AboutView(){_ref=AboutView.__super__.constructor.apply(this,arguments)
return _ref}__extends(AboutView,_super)
AboutView.prototype.viewAppended=function(){var canSeeExMembers,member,_i,_len,_ref1
this.addSubView(new KDHeaderView({title:"The Team",type:"big",cssClass:"team-title"}))
this.activeController=new KDListViewController({itemClass:AboutListItem,listView:new KDListView({tagName:"ul"}),scrollView:!1,wrapper:!1},{items:KD.team.active})
this.addSubView(this.activeController.getView())
canSeeExMembers=!1
_ref1=KD.team.active
for(_i=0,_len=_ref1.length;_len>_i;_i++){member=_ref1[_i]
if(KD.nick()===member.username){canSeeExMembers=!0
break}}if(canSeeExMembers){this.suspendedController=new KDListViewController({itemClass:AboutListItem,listView:new KDListView({tagName:"ul"}),scrollView:!1,wrapper:!1},{items:KD.team.suspended})
this.addSubView(new KDHeaderView({title:"Ex-members",type:"big",cssClass:"team-title"}))
return this.addSubView(this.suspendedController.getView())}}
return AboutView}(KDView)
AboutListItem=function(_super){function AboutListItem(options,data){var username
null==options&&(options={})
options.tagName="li"
options.type="team"
AboutListItem.__super__.constructor.call(this,options,data)
username=this.getData().username
this.avatar=new AvatarImage({origin:username,bind:"load",load:function(){return this.setClass("in")},size:{width:160}})
this.link=new ProfileLinkView({origin:username})}__extends(AboutListItem,_super)
AboutListItem.prototype.viewAppended=JView.prototype.viewAppended
AboutListItem.prototype.pistachio=function(){return"<figure>\n  {{> this.avatar}}\n</figure>\n<figcaption>\n  {{> this.link}}\n  {cite{#(title)}}\n</figcaption>"}
return AboutListItem}(KDListItemView)

//@ sourceMappingURL=/js/__app.about.0.0.1.js.map