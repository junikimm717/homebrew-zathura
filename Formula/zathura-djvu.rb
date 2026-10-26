class ZathuraDjvu < Formula
  desc "DJVU plugin for zathura"
  homepage "https://pwmt.org/projects/zathura-djvu/"
  url "https://github.com/pwmt/zathura-djvu/archive/refs/tags/2026.02.03.tar.gz"
  sha256 "4b498cc2df24d6b57452f82d07fc829d7f352bc2215b4707f540a34d66a0a72a"
  license "Zlib"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  depends_on "cmake" => :build
  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkg-config" => :build
  depends_on "djvulibre"
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
    system "true"
  end
end
