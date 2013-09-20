class DemosMainView extends KDScrollView

  viewAppended:->

    @addSubView scene = new EnvironmentScene

    rulesContainer    = new EnvironmentContainer
      title           : "Rules"
      itemClass       : EnvironmentRuleItem
    scene.addContainer rulesContainer

    domainsContainer  = new EnvironmentContainer
      title           : "Domains"
      itemClass       : EnvironmentDomainItem
    scene.addContainer domainsContainer, x: 300

    machinesContainer = new EnvironmentContainer
      title           : "Machines"
      itemClass       : EnvironmentMachineItem
    scene.addContainer machinesContainer, x: 580

    rulesContainer.addItem
      title       : 'Internal Access'
      description : 'Deny: All, Allow: 127.0.0.1'
      activated   : yes

    rulesContainer.addItem
      title       : 'No China'
      description : 'Deny: All, Allow: Loc: [China]'
      notes       : 'We need this for bla bla bla...'

    domainsContainer.addItem
      title       : 'gokmen.kd.io'
      description : 'Main domain'
      activated   : yes

    domainsContainer.addItem
      title       : 'git.gokmen.kd.io'
      description : 'Koding GIT repository'
      notes       : 'I keep all the source in here.'

    domainsContainer.addItem
      title       : 'svn.gokmen.kd.io'
      description : 'Koding SVN repository'

    machinesContainer.addItem
      title : 'vm-0.gokmen.koding.kd.io'
      usage : 20

    machinesContainer.addItem
      title     : 'vm-1.gokmen.koding.kd.io'
      usage     : 45
      activated : yes

class EnvironmentScene extends KDDiaScene
  constructor:->
    super
      cssClass  : 'environments-scene'
      lineWidth : 1

class EnvironmentContainer extends KDDiaContainer
  constructor:(options={}, data)->
    options.cssClass  = 'environments-container'
    options.draggable = yes
    super options, data

    title = @getOption 'title'
    @header = new KDHeaderView {type : "medium", title}

  viewAppended:->
    super
    @addSubView @header

  addDia:(diaObj, pos)->
    pos = x: 20, y: 60 + @diaCount() * 50
    super diaObj, pos
    @updateHeight()

  diaCount:-> Object.keys(@dias).length
  updateHeight:-> @setHeight 80 + @diaCount() * 50

class EnvironmentItem extends KDDiaObject
  constructor:(options={}, data)->
    options.cssClass = KD.utils.curry 'environments-item', options.cssClass
    options.jointItemClass = EnvironmentItemJoint
    options.draggable = no
    super options, data

  viewAppended:->
    super
    @setClass 'activated'  if @getData().activated?

  pistachio:->
    """
      <div class='details'>
        {h3{#(title)}}
        {{#(description)}}
      </div>
    """

class EnvironmentRuleItem extends EnvironmentItem
  constructor:(options={}, data)->
    options.joints             = ['right']
    options.cssClass           = 'rule'
    options.allowedConnections =
      EnvironmentDomainItem : ['left']
    super options, data

class EnvironmentDomainItem extends EnvironmentItem
  constructor:(options={}, data)->
    options.joints = ['left', 'right']
    options.cssClass = 'domain'
    options.allowedConnections =
      EnvironmentRuleItem    : ['right']
      EnvironmentMachineItem : ['left']
    super options, data

class EnvironmentMachineItem extends EnvironmentItem
  constructor:(options={}, data)->
    options.joints = ['left']
    options.cssClass = 'machine'
    options.allowedConnections =
      EnvironmentDomainItem : ['right']
    super options, data
    @usage = new KDProgressBarView

  viewAppended:->
    super
    @usage.updateBar @getData().usage, '%', ''

  pistachio:->
    """
      <div class='details'>
        {h3{#(title)}}
        {{> @usage}}
      </div>
    """

class EnvironmentItemJoint extends KDDiaJoint
  constructor:(options={}, data)->
    options.cssClass = 'environments-joint'
    options.size     = 4
    super options, data
