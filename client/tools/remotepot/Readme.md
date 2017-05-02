# remotepot

this is for koding devs who work on vms and want to have their scripts and stuff served from localhost instead.

# usage

Whip up a koding server _on your vm_ in backend mode:

```sh
./configure --host dev.<your_username>.koding.io:8090
./run backend
```

If you haven't loaded chrome extension yet, open chrome and type in `chrome://extensions` in address bar, click on `Load unpacked extension` and select `client/tools/remotepot/extension` folder.

This extension redirects all requests to `a/p/p` path to your localhost. So to make this work, your vm server url pattern must fit in `*://*.koding.io:8090` form.

Now you have loaded your extension and redirecting requests and stuff, you need to serve those stuff from your localhost.

Go to `client/tools/remotepot` _on your localhost_, and type in:

`node serve.js`

This will serve your files in `website` folder on port `8090`, and when you hit your vm server on browser you will see scripts and stuff are being served from localhost, yay.

Go to your client folder and type in `make` and do all kinds of crazy things.

# license

koding