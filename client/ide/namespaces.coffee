window.IDE = {}


window.IDE.splashMarkups =
  getTerminal: (nickname) ->
    return """<div class="kdview webterm"><div class="kdview console ubuntu-mono green-on-black" style="font-size: 14px;"><div contenteditable="true" spellcheck="false" style="cursor: text;"><div>#{nickname}:~$&nbsp;<span class="outlined" style="">&nbsp;</span></div></div></div></div>"""

  getFileTree: (nickname, machineLabel) ->
    return """<div class="kdview kdscrollview jtreeview-wrapper dim"><ul class="kdview kdlistview kdlistview-default jtreeview expanded last-item-selected"><li class="kdview kdlistitemview kdlistitemview-finderitem jtreeitem expanded has-sub-items selected"><div class="vm" style="margin-left: 0px;"><div class="vm-header"><span class="vm-info">#{machineLabel}</span><div class="buttons"><button type="button" class="kdbutton terminal" id="kd-276"><span class="icon hidden"></span><span class="button-title"></span></button><span class="chevron"></span></div></div><div class="kdselectbox "><span class="title">/home/#{nickname}</span><span class="arrows"></span></div></div></li><ul class="kdview kdlistview kdlistview-default jtreeview expanded"><li class="kdview kdlistitemview kdlistitemview-finderitem jtreeitem"><div class="folder" style="margin-left: 14px;"><span class="icon"></span><span class="title">Applications</span><span class="chevron"></span></div></li><li class="kdview kdlistitemview kdlistitemview-finderitem jtreeitem"><div class="folder" style="margin-left: 14px;"><span class="icon"></span><span class="title">Backup</span><span class="chevron"></span></div></li><li class="kdview kdlistitemview kdlistitemview-finderitem jtreeitem"><div class="folder" style="margin-left: 14px;"><span class="icon"></span><span class="title">Documents</span><span class="chevron"></span></div></li><li class="kdview kdlistitemview kdlistitemview-finderitem jtreeitem"><div class="folder" style="margin-left: 14px;"><span class="icon"></span><span class="title">Web</span><span class="chevron"></span></div></li><li class="kdview kdlistitemview kdlistitemview-finderitem jtreeitem"><div class="file" style="margin-left: 14px;"><span class="icon bash_logout unknown"></span><span class="title">.bash_logout</span><span class="chevron"></span></div></li><li class="kdview kdlistitemview kdlistitemview-finderitem jtreeitem"><div class="file" style="margin-left: 14px;"><span class="icon bashrc unknown"></span><span class="title">.bashrc</span><span class="chevron"></span></div></li><li class="kdview kdlistitemview kdlistitemview-finderitem jtreeitem"><div class="file" style="margin-left: 14px;"><span class="icon profile unknown"></span><span class="title">.profile</span><span class="chevron"></span></div></li></ul></ul></div>"""


window.IDE.contents =
  workspace: """
    # Welcome to your new Koding workspace

    This workspace, which lives inside the 'Workspaces' folder of your
    home directory, is the place where you can store all relevant and
    related files to this project.

    Workspaces help keep your projects organized. You can create any
    number of sub-folders within this workspace in order to further
    organize your work.

    As you move back and forth between your workspaces, Koding will try
    and remember everything about each workspace. This includes things
    like IDE settings, files open, Terminals open, etc.

    You can create as many new workspaces as you need on your VM.

    Enjoy and Happy Koding!
  """
