# tools for creating keymap config

type `make` to create json & csv files under `out/` directory.

see: https://www.pivotaltracker.com/story/show/84690132

# keymap item

```json
  {
    "name": "w#gototabnumber1",
    "description": "Go to Tab #1",
    "binding": [
      [
        "ctrl+1"
      ],
      [
        "command+1"
      ]
    ],
    "readonly": false,
    "enabled": true,
    "hidden": false,
    "options": {
      "mousetrap": {
        "global": true
      }
    }
  },
```

- `name` is unique id for this shortcut~~, which also acts some sort of namespace. here `w#gototabnumber1` denotes that this shortcut is in `w` group, and eventually will be displayed along with other shortcuts in `w` group.~~
- `binding` is an array of two arrays. these arrays hold key-bindings defined for windows and mac respectively. shortcuts are always in mousetrap syntax.
- if a shortcut is `readonly` it cannot be overridden by any shortcut in same namespace. we only display them but do not allow them to be set.
- `hidden` shortcuts are shortcuts that we had to implicitly override for some reason (eg ace#showSettingsMenu) and have to keep them around to prevent getting them overridden. they are `hidden` because they are not displayed.

# ace-to-json.js

json repr of ace shortcuts.

depends on:

- `ace-commands.js`: includes all the shortcuts extracted from ace 1.1.3. (see: https://github.com/ajaxorg/ace/tree/v1.1.3/lib/ace/commands)

- `ace-descriptions.json`

# terminal-to-json.coffee

json repr of shortcuts extracted from `Terminal/AppController#keyBindings`

# editor-to-json.js

json repr of shortcuts extracted from `Ace/ace.coffee` (see: `addKeyCombo` calls)

# workspace-to-json.coffee

json repr of shortcuts extracted from `IDE/AppControllerOptions#keyBindings`

depends on:

- `workspace-descriptions.json`

# to-csv.py

turns keymap json into csv. so people can make revisions using google spreadsheets.

(see: `UI/UX > IDE and Terminal > Shortcuts` under google drive)

usage:

```
node ace-to-json.js|python to-csv.py
```

