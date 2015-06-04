#!/usr/bin/env python
"""
A script for compiling a kite and uploading to S3.

usage: upload-kite.py [-h] [--upload] kite-name main-file

"""
import argparse
import os
import shutil
import subprocess
import sys
import tarfile
import tempfile

import boto
from boto.s3.key import Key


AWS_KEY = ''
AWS_SECRET = ''


def main():
    parser = argparse.ArgumentParser(
        description="Compile a kite and upload to S3.")
    parser.add_argument('kite_name', help="name of the kite")
    parser.add_argument('main_file', help='path of the ".go" file that contains main()')
    parser.add_argument('--upload', action='store_true', help="upload to s3")
    args = parser.parse_args()

    workdir = tempfile.mkdtemp()
    try:
        print "Building kite..."
        executable_path = os.path.join(workdir, args.kite_name)
        cmd = "go build -o %s %s" % (executable_path, args.main_file)
        try:
            subprocess.check_call(cmd.split())
        except subprocess.CalledProcessError:
            print "Cannot compile kite. Try manually."
            sys.exit(1)

        # Get the version number from compiled binary
        version = subprocess.check_output([executable_path, "-version"]).strip()
        assert len(version.split(".")) == 3, "Please use 3-digits versioning"
        print "Version:", version

        # Create bundle
        bundle_name = "%s-%s.kite" % (args.kite_name, version)
        bundle_path = os.path.join(workdir, bundle_name)
        os.mkdir(bundle_path, 0700)
        bin_path = os.path.join(bundle_path, "bin")
        os.mkdir(bin_path, 0700)
        shutil.move(executable_path, bin_path)

        print "Making tar.gz..."
        tar_name = "%s.tar.gz" % bundle_name
        tar_path = os.path.join(workdir, tar_name)
        with tarfile.open(tar_path, "w:gz") as tar:
            tar.add(bundle_path, arcname=bundle_name, recursive=True)

        # Move the tar to current working directory
        shutil.move(tar_path, tar_name)

        # Upload to Amazon S3
        if args.upload:
            print "Uploading to Amazon S3..."
            c = boto.connect_s3(AWS_KEY, AWS_SECRET)
            b = c.get_bucket('koding-kites')

            tarfile_key = Key(b)
            tarfile_key.key = tar_name
            if tarfile_key.exists():
                print "This version is already uploaded. " \
                      "Please do not overwrite the uploaded version, " \
                      "increment the version number and upload it again."
                sys.exit(1)

            tarfile_key.set_contents_from_filename(tar_name)
            tarfile_key.make_public()

            # Upload it again as kitename-latest.kite.tar.gz
            # kd tool install the latest version when version is not given.
            tarfile_key.name = "%s-latest.kite.tar.gz" % args.kite_name
            tarfile_key.set_contents_from_filename(tar_name)
            tarfile_key.make_public()

        print "Generated package:", tar_name

        if not args.upload:
            print "Did not upload to S3. " \
                  "If you want to upload, run with --upload flag."

    finally:
        shutil.rmtree(workdir)


if __name__ == "__main__":
    main()
