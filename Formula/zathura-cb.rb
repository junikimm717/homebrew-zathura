class ZathuraCb < Formula
  desc "Comic book plugin for zathura"
  homepage "https://pwmt.org/projects/zathura-cb/"
  url "https://github.com/pwmt/zathura-cb/archive/refs/tags/2026.02.03.tar.gz"
  sha256 "d04887cf29b7e635efb4a4a3316e4f032435611445f20940f7f0e288cee20576"
  license "Zlib"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  depends_on "cmake" => :build
  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkg-config" => :build
  depends_on "libarchive"
  depends_on "zathura"

  def install
    inreplace "meson.build", "zathura.get_variable(pkgconfig: 'plugindir')", "'#{lib}/zathura'"
    mkdir "build" do
      system "meson", *std_meson_args, ".."
      system "ninja"
      system "ninja", "install"
    end
  end

  test do
    system "true" # TODO
  end
end
