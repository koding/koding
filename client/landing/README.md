Koding
======

Koding's landing/marketing pages including home and login.

Requirements
------------
Make sure to install [requirements](https://github.com/Ensighten/spritesmith#requirements) for the sprite builder.

Install & Run
------------

After you have the requirements installed, clone the repo and do:

```coffeescript
npm i
gulp
```

then follow the onscreen instructions.

-------------

### OR

##### Start a site  manually

```coffeescript
# cd into the site

cd ./site.landing

# gulp it
# devMode activates the sourcemaps and its server

gulp --devMode
```

##### Start the server:

```coffeescript
# cd back into the main repo

cd ..
gulp serve
```

See your page at localhost:5000
Registration and login will make XHR calls to Koding and will work once your campaign site is pushed to Koding, but for local testings, we should fake that data by adding XHR endpoints to this local server so that entire flows can be made and simulated before pushing the final product.


##### Build all sites:

```coffeescript
gulp build-all-sites
```

for more check the main and site specific `gulpfile`'s
