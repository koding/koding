# shortcuts

manages keyboard shortcuts.

# configuration

JSON files under [config](./config) contain default key-binding configurations.

See [keyconfig](https://github.com/koding/keyconfig) for the config spec.

# usage

Once you have defined your shortcut sets, you need to set a `shortcuts` field in an application's `bant.json` file, which is an array of strings.

For example if you have defined two config sets named `qux` and `quux`, you add this:

```
...
{
  "shortcuts": [
    "qux",
    "quux"
  ] 
}
...
```

Then when you start the application, democracy kicks in and magically binds/unbinds your shortcuts, and things happen.

Also see [shortcuts](https://github.com/koding/shortcuts) which is the primary api that orchestrates all these crazy things.

# license

2015 Koding, Inc