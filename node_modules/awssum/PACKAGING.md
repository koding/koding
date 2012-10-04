# Packaging #

Update this file, and check it in:

    export VERSION=0.10.0
    vi package.json
    git commit -m 'Bump version number to 0.10.0' PACKAGING.md package.json

    git tag v$VERSION
    git push origin v$VERSION

    cd /tmp/
    rm -rf node-awssum
    git clone ~chilts/src/appsattic-node-awssum/ node-awssum
    cd node-awssum
    npm publish
    cd ~/src/appsattic-node-awssum/

(Ends)
