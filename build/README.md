Build.go creates a `.deb` package. To create a new `.deb` package run the
command below on an Ubuntu box:


```
go run build.go -e production -b 30
```

* `-e` defines the environment, it can be `production` or `development`.
* `-b` defines the build number, it should be an integer.

