#!/usr/bin/env python2.7
"""
A script for packaging and releasing kd tool for OS X and Linux platforms.
It can also upload the generated package file to S3 if you provide --upload flag.

usage: release.py [-h] [--upload]

Run it with the same folder as kd.go. It will put the generated files into
the current working directory.

On OS X, the brew formula can be installed with the following command:

    brew install kd.rb

On Linux, the deb package can be installed with the following command:

    dpkg --force-architecture -i kd-0.0.1-linux.deb

Note:
"--force-architecture" is only needed on 64-bit systems since we only compile
the tool for i386 architecture for now. Since the kd binary is static-linked
it can safely run on amd64 architecture.

"""
import argparse
import hashlib
import os
import shutil
import subprocess
import sys
import tarfile
import tempfile

import boto
from boto.s3.key import Key


AWS_KEY = 'AKIAJSUVKX6PD254UGAA'
AWS_SECRET = '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'

BREW_FORMULA = """\
require 'formula'

class Kd < Formula
  homepage 'http://koding.com'
  # url and sha1 needs to be changed after new binary is uploaded.
  url '{url}'
  sha1 '{sha1}'

  def install
    bin.install "kd"
  end

  def test
    system "#{{bin}}/kd", "version"
  end
end
"""

DEB_CONTROL = """\
Package: kd
Version: {version}
Section: utils
Priority: optional
Architecture: amd64
Essential: no
Maintainer: Koding Developers <hello@koding.com>
Description: Koding command-line tool.
"""


def build_osx(binpath, version):
    print "Making tar file..."
    tarname = "kd-%s-osx.tar.gz" % version
    with tarfile.open(tarname, "w:gz") as tar:
        tar.add(binpath, arcname="kd")
    return tarname


def build_linux(binpath, version):
    workdir = tempfile.mkdtemp()
    try:
        debname = "kd-%s-linux" % version
        packagedir = os.path.join(workdir, debname)
        os.mkdir(packagedir)
        debiandir = os.path.join(packagedir, "DEBIAN")
        os.mkdir(debiandir)
        controlpath = os.path.join(debiandir, "control")
        with open(controlpath, "w") as f:
            f.write(DEB_CONTROL.format(version=version))
        usrdir = os.path.join(packagedir, "usr")
        os.mkdir(usrdir)
        bindir = os.path.join(usrdir, "bin")
        os.mkdir(bindir)
        shutil.move(binpath, bindir)
        debfile = "%s.deb" % debname
        subprocess.check_call(["fakeroot", "dpkg-deb", "--build",
                               packagedir, debfile])
        return debfile
    finally:
        shutil.rmtree(workdir)


def postbuild_osx(package_name, args, bucket, package_s3_key):
    if args.upload:
        url = package_s3_key.generate_url(expires_in=0, query_auth=False)
    else:
        # For testing "brew install" locally
        url = "http://127.0.0.1:8000/%s" % package_name

    print "Generating formula..."
    sha1 = sha1_file(package_name)
    formula_str = BREW_FORMULA.format(url=url, sha1=sha1)
    with open("kd.rb", "w") as f:
        f.write(formula_str)

    if args.upload:
        print "Uploading new brew formula..."
        formula_key = Key(bucket)
        formula_key.key = "kd.rb"
        formula_key.set_contents_from_string(formula_str)
        formula_key.make_public()
        formula_url = formula_key.generate_url(expires_in=0, query_auth=False)

        print "kd tool has been uplaoded successfully.\n" \
              "Users can install it with:\n    " \
              "brew install \"%s\"" % formula_url
    else:
        print "Did not upload to S3. " \
              "If you want to upload, run with --upload flag."


def postbuild_linux(package_name, args, bucket, package_s3_key):
    if args.upload:
        print "Uploading again as kd-latest.linux.deb ..."
        latest = Key(bucket)
        latest.key = "kd-latest-linux.deb"
        latest.set_contents_from_filename(package_name)
        latest.make_public()
        print "Uploaded:", latest.generate_url(expires_in=0, query_auth=False)


def main():
    parser = argparse.ArgumentParser(
        description="Compile kd tool and upload to S3.")
    parser.add_argument('--upload', action='store_true', help="upload to s3")
    parser.add_argument('--overwrite', action='store_true', help="overwrite existing package")
    args = parser.parse_args()

    workdir = tempfile.mkdtemp()
    try:
        tardir = os.path.join(workdir, "kd")  # dir to be tarred
        os.mkdir(tardir)
        binpath = os.path.join(tardir, "kd")
        cmd = "go build -o %s %s" % (binpath, "main/kd.go")
        env = os.environ.copy()
        env["GOARCH"] = "amd64"   # we only build for 64-bit
        env["CGO_ENABLED"] = "1"  # cgo must be enabled for some functions to run correctly

        # Decide on platform (osx, linux, etc.)
        if sys.platform.startswith("linux"):
            env["GOOS"] = "linux"
            platform = "linux"
        elif sys.platform.startswith("darwin"):
            env["GOOS"] = "darwin"
            platform = "osx"
        else:
            print "%s platform is not supported" % sys.platform
            sys.exit(1)

        # Compile kd tool source code
        print "Building for platform: %s" % platform
        try:
            subprocess.check_call(cmd.split(), env=env)
        except subprocess.CalledProcessError:
            print "Cannot compile kd tool. Try manually."
            sys.exit(1)

        # Get the version number from compiled binary
        version = subprocess.check_output([binpath, "version"]).strip()
        assert len(version.split(".")) == 3, "Please use 3-digits versioning"
        print "Version:", version

        # Build platform specific package
        build_function = globals()["build_%s" % platform]
        package = build_function(binpath, version)
        if not os.path.exists(package):
            print "Build is unsuccessful."
            sys.exit(1)
        print "Generated package:", package

        # Upload to Amazon S3
        bucket = package_key = None
        if args.upload:
            print "Uploading to Amazon S3..."
            s3_connection = boto.connect_s3(AWS_KEY, AWS_SECRET)
            bucket = s3_connection.get_bucket('kd-tool')

            package_key = Key(bucket)
            package_key.key = package
            if package_key.exists() and not args.overwrite:
                print "This version is already uploaded. " \
                      "Please do not overwrite the uploaded version, " \
                      "increment the version number and upload it again. " \
                      "If you must, you can use --overwrite option."
                sys.exit(1)

            package_key.set_contents_from_filename(package)
            package_key.make_public()
            url = package_key.generate_url(expires_in=0, query_auth=False)
            print "Package is uploaded to S3:", url

        # Run post-build actions
        postbuild_function = globals().get("postbuild_%s" % platform)
        if postbuild_function:
            postbuild_function(package, args, bucket, package_key)

    finally:
        shutil.rmtree(workdir)


def sha1_file(path):
    """Calculate sha1 of path. Read file in chunks."""
    assert os.path.isfile(path)
    chunk_size = 1024 * 1024  # 1M
    sha1_checksum = hashlib.sha1()
    with open(path, "rb") as f:
        byte = f.read(chunk_size)
        while byte:
            sha1_checksum.update(byte)
            byte = f.read(chunk_size)
    return sha1_checksum.hexdigest()


if __name__ == "__main__":
    main()
