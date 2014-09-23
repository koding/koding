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

Scaffold a site:

```
# scaffold a site
gulp site --siteName=campaign

# cd into the created site
cd ./site.campaign
gulp --site=site.campaign --devMode
```

Start the server:

```
gulp serve
```

Build all sites:

```
gulp build
```

for more check the main and site specific `gulpfile.coffee`'s