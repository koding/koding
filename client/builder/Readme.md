# builder

builds koding client.

# usage

```
usage: coffee bin/cmd.coffee {options}

Options:
  --help, -h               show this message
  --version, -V            show version number
  --use                    a bant manifest file to require. files can be globs.
  --basedir                specify the base dir for relative path resolution
  --outdir                 specify the outdir
  --thirdparty-dir         specify the thirdparty libs dir
  --assets-dir             specify the assets dir
  --baseurl                specify the public folder that is relative to application's root
  --globals-file           specify the globals file that will be exposed as 'globals'
  --config-file            specify the client config file that was generated with './configure'
  --watch-js               enable watch mode for scripts
  --watch-css              enable watch mode for styles
  --watch-sprites          enable watch mode for sprites
  --debug-js               enable source maps for scripts
  --debug-css              enable source maps for styles
  --minify-js              minify scripts
  --minify-css             minify styles
  --extract-js-sourcemaps  extract source maps in debug mode
  --rev-id                 write outfiles into $outdir/$git-revision-id
  --notify                 enable system notifications in watch mode
  --notify-sound           play audio with system notifications
  --scripts                build scripts
  --styles                 build styles
  --sprites                build sprites
  --assets                 copy assets
  --thirdparty             copy thirdparty
  --verbose, -v            make the operation more talkative
```

You can also explicitly negate a field with `--no-key`.

```
cmd.coffee --no-rev-id
```

# license

2015 Koding, Inc.