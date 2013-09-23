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