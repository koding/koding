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
  --baseurl                specify the public folder that is relative to application's root    
  --thirdparty-dir         specify the thirdparty libs dir                                     
  --assets-dir             specify the assets dir                                              
  --globals-file           specify the globals file that will be exposed as 'globals'          
  --config-file            specify the client config file that was generated with './configure'
  --js-outfile             write js bundle to this file                                        
  --css-outdir             write css bundles to this dir                                       
  --assets-outdir          write assets to this dir                                            
  --thirdparty-outdir      write thirdparty libs to this dir                                   
  --watch-js               enable watch mode for scripts                                         [default: false]
  --watch-css              enable watch mode for styles                                          [default: false]
  --debug-js               enable source maps for scripts                                        [default: false]
  --debug-css              enable source maps for styles                                         [default: false]
  --minify-js              minify scripts with uglifyjs                                          [default: false]
  --minify-css             minify styles with clean-css                                          [default: false]
  --scripts                build scripts                                                         [default: true]
  --styles                 build styles                                                          [default: true]
  --sprites                build sprites                                                         [default: true]
  --assets                 copy assets                                                           [default: true]
  --thirdparty             copy thirdparty                                                       [default: true]
  --extract-js-sourcemaps  extract source maps in debug mode                                     [default: false]
  --rev-id                 add revision id to output filenames                                   [default: true]
  --notify                 disable system notifications in watch mode                            [default: false]
  --verbose, -v            make the operation more talkative                                     [default: false]
```

You can also explicitly negate a field with `--no-key`.

```
cmd.coffee --no-rev-id
```

# license

2015 Koding, Inc.