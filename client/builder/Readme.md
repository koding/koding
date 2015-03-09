# builder

builds koding client.

# usage

```
Options:
  --help, -h            show this message                                                          
  --version, -V         show version number                                                        
  --use                 a bant manifest file to require. files can be globs.                       
  --basedir             specify the base dir for relative path resolution                          
  --baseurl             specify the public folder that is relative to application's root           
  --thirdparty-dir      specify the thirdparty libs dir                                            
  --globals-file        specify the globals file that will be exposed as 'globals'                 
  --config-file         specify the client config file that was generated with ./configure         
  --js-outfile          write js bundle to this file                                               
  --css-outdir          write css bundles to this dir                                              
  --assets-outdir       write assets to this dir                                                   
  --thirdparty-outdir   write thirdparty libs to this dir                                          
  --sourcemaps-outfile  write source maps to this file. if unspecified builder inlines source maps.
  --watch-js            enable watch mode for scripts                                                [default: false]
  --watch-css           enable watch mode for styles                                                 [default: false]
  --debug-js            enable source maps for scripts                                               [default: false]
  --debug-css           enable source maps for styles                                                [default: false]
  --minify-js           minify scripts with uglifyjs                                                 [default: false]
  --minify-css          minify styles with clean-css                                                 [default: false]
  --notify              enable system notifications                                                  [default: false]
  --verbose, -v         make the operation more talkative                                            [default: false]
```

# license

2015 Koding, Inc.