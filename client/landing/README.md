Koding
======

Koding's landing/marketing pages including home and login.

Requirements
------------
Make sure to install [requirements](https://github.com/Ensighten/spritesmith#requirements) for the sprite builder.

Installation
------------

After you have the requirements installed, clone the repo and do:

```
npm i
```

#### Start a site:

```
# cd into the site
cd ./site.campaign

#gulp it
gulp --siteName=landing  --devMode
```

#### Start the server:

```
# cd back into the main repo
cd ..
gulp serve
```

See your page at localhost:5000
Registration and login will make XHR calls to Koding and will work once your campaign site is pushed to Koding, but for local testings, we should fake that data by adding XHR endpoints to this local server so that entire flows can be made and simulated before pushing the final product.


#### Scaffold a site:

```
# scaffold a site
gulp site --siteName=campaign

# cd into the created site
cd ./site.campaign
gulp --site=site.campaign --devMode
```

#### Build all sites:

```
gulp build
```

for more check the main and site specific `gulpfile`'s
