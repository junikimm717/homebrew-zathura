class ZathuraPs < Formula
  desc "Postscript backend plugin for zathura"
  homepage "https://pwmt.org/projects/zathura-ps/"
  url "https://github.com/pwmt/zathura-ps/archive/refs/tags/2026.02.03.tar.gz"
  sha256 "4813cd08def2edff7822de846d242637080c647b8fa7a97d841d2f1c6933c4e6"
  license "Zlib"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  depends_on "cmake" => :build
  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkg-config" => :build
  depends_on "libspectre"
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
