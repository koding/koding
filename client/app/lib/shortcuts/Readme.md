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

# custom shortcuts (eg ace)

I believe [shortcuts](http://github.com/koding/shortcuts) should not embed such logic and totally be _shortcut type_ agnostic; its api allows dealing with such cases indeed.

Passing `silent` as the 4th argument to `shortcuts#update` makes sure its internal `keyconfig#change` listener won't get dispatched thus rendering the model in question unbound.

Plus, there is the `options` object you can use to denote such weirdos.

Just make sure you don't mix in any _custom shortcut_ within a regular set in [bant](http://github.com/bantjs/bant) manifests; since these sets are automatically thought to be [shortcuts](http://github.com/koding/shortcuts) compatible.

# license

2015 Koding, Inc