require 'formula'

class Kite < Formula
  homepage 'http://kite.koding.com'
  # url and sha1 needs to be changed after new binary is uploaded.
  url 'https://kite-cli.s3.amazonaws.com/kite-0.0.8-osx.tar.gz'
  sha1 'fc24157d1d33c2c873a109ed83819a7879424841'

  def install
    bin.install "kite"
  end

  def test
    system "#{bin}/kite", "version"
  end
end
