class ZathuraPdfPoppler < Formula
  desc "Poppler backend plugin for zathura"
  homepage "https://pwmt.org/projects/zathura-pdf-poppler/"
  url "https://github.com/pwmt/zathura-pdf-poppler/archive/refs/tags/2026.02.03.tar.gz"
  sha256 "959a657edcbce18ed19cde8ba0a60b9dabbb20c25051d557c598ab2527edcfc5"
  license "Zlib"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  depends_on "cmake" => :build
  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkg-config" => :build
  depends_on "poppler"
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
