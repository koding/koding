# koding.com website

This directory contains the jekyll implementation for the koding.com website.

## Contributions Welcome

If you find a typo or you feel like you can improve the HTML, CSS, or JavaScript, we welcome contributions. Feel free to open issues or pull requests like any normal GitHub project, and we'll merge it in.

## Running the Site Locally

Running the site locally is simple. First you need a working copy of Ruby >= 2.0 and Bundler.

#### installation:

```bash
gem install jekyll bundler
```

#### configuration:

in `_config.yml` make sure you set the `url` to your choice of host e.g. `localhost:4000`

```yml
url: 'http://localhost:4000'
```

#### run:

this will run the site and watch for changes, if you want livereload just add `--livereload`

```bash
bundle exec jekyll serve --livereload
```

Then open up http://localhost:4000

#### license:

Apache 2.0