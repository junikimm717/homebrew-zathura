class ZathuraPdfMupdf < Formula
  desc "MuPDF backend plugin for zathura"
  homepage "https://pwmt.org/projects/zathura-pdf-mupdf/"
  url "https://github.com/pwmt/zathura-pdf-mupdf/archive/refs/tags/2026.02.03.tar.gz"
  sha256 "0e718162054a0cd673bfa654f5d52ae03428665d154b00c897abf7014375bfff"
  license "Zlib"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  depends_on "cmake" => :build
  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkg-config" => :build
  depends_on "mupdf"
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
