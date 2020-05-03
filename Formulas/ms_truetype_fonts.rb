class MsTruetypeFonts < FontFormula

  desc "Microsoft TrueType Core fonts for the Web"
  homepage "https://www.microsoft.com"

  resource "EUupdate.EXE" do
    url [
      "https://download.microsoft.com/download/a/1/8/a180e21e-9c2b-4b54-9c32-bf7fd7429970/EUupdate.EXE",
      "https://nchc.dl.sourceforge.net/project/corefonts/the%20fonts/final/EUupdate.EXE"
    ]
    sha256 "464dd2cd5f09f489f9ac86ea7790b7b8548fc4e46d9f889b68d2cdce47e09ea8"
  end

  provides_font("Arial", match_styles_from_file: {
    "Regular" => "Arial.ttf",
    "Bold" => "ArialBd.ttf",
    "Italic" => "ArialI.ttf",
    "Bold Italic" => "ArialBI.ttf"
  })

  provides_font("Trebuchet", match_styles_from_file: {
    "Regular" => "trebuc.ttf",
    "Bold" => "trebucbd.ttf",
    "Italic" => "trebucit.ttf",
    "Bold Italic" => "trebucbi.ttf"
  })

  provides_font("Verdana", match_styles_from_file: {
    "Regular" => "Verdana.ttf",
    "Bold" => "Verdanab.ttf",
    "Italic" => "Verdanai.ttf",
    "Bold Italic" => "Verdanaz.ttf"
  })

  provides_font("Times New Roman", match_styles_from_file: {
    "Regular" => "Times.ttf",
    "Bold" => "TimesBd.ttf",
    "Italic" => "TimesI.ttf",
    "Bold Italic" => "TimesBI.ttf"
  })

  resource "andale32.exe" do
    urls [
      "https://nchc.dl.sourceforge.net/project/corefonts/the%20fonts/final/andale32.exe",
      "http://sft.if.usp.br/msttcorefonts/andale32.exe"
    ]
    sha256 "0524fe42951adc3a7eb870e32f0920313c71f170c859b5f770d82b4ee111e970"
  end

  resource "arialb32.exe" do
    urls [
      "https://nchc.dl.sourceforge.net/project/corefonts/the%20fonts/final/arialb32.exe",
      "http://sft.if.usp.br/msttcorefonts/arialb32.exe"
    ]
    sha256 "a425f0ffb6a1a5ede5b979ed6177f4f4f4fdef6ae7c302a7b7720ef332fec0a8"
  end

  resource "comic32.exe" do
    urls [
      "https://nchc.dl.sourceforge.net/project/corefonts/the%20fonts/final/comic32.exe",
      "http://sft.if.usp.br/msttcorefonts/comic32.exe"
    ]
    sha256 "9c6df3feefde26d4e41d4a4fe5db2a89f9123a772594d7f59afd062625cd204e"
  end

  resource "courie32.exe" do
    urls [
      "https://nchc.dl.sourceforge.net/project/corefonts/the%20fonts/final/courie32.exe",
      "http://sft.if.usp.br/msttcorefonts/courie32.exe"
    ]
    sha256 "bb511d861655dde879ae552eb86b134d6fae67cb58502e6ff73ec5d9151f3384"
  end

  resource "georgi32.exe" do
    urls [
      "https://nchc.dl.sourceforge.net/project/corefonts/the%20fonts/final/georgi32.exe",
      "http://sft.if.usp.br/msttcorefonts/georgi32.exe"
    ]
    sha256 "2c2c7dcda6606ea5cf08918fb7cd3f3359e9e84338dc690013f20cd42e930301"
  end

  resource "impact32.exe" do
    urls [
      "https://nchc.dl.sourceforge.net/project/corefonts/the%20fonts/final/impact32.exe",
      "http://sft.if.usp.br/msttcorefonts/impact32.exe"
    ]
    sha256 "6061ef3b7401d9642f5dfdb5f2b376aa14663f6275e60a51207ad4facf2fccfb"
  end

  resource "webdin32.exe" do
    urls [
      "https://nchc.dl.sourceforge.net/project/corefonts/the%20fonts/final/webdin32.exe",
      "http://sft.if.usp.br/msttcorefonts/webdin32.exe"
    ]
    sha256 "64595b5abc1080fba8610c5c34fab5863408e806aafe84653ca8575bed17d75a"
  end

  provides_font("Andale Mono", match_styles_from_file: {
    "Regular" => "AndaleMo.TTF"
  })

  provides_font("Arial Black", match_styles_from_file: {
    "Regular" => "AriBlk.TTF"
  })

  provides_font("Comic Sans", match_styles_from_file: {
    "Regular" => "Comic.TTF",
    "Bold" => "Comicbd.TTF"
  })

  provides_font("Courier", match_styles_from_file: {
    "Regular" => "cour.ttf",
    "Italic" => "couri.ttf",
    "Bold Italic" => "courbi.ttf",
    "Bold" => "courbd.ttf"
  })

  provides_font("Georgia", match_styles_from_file: {
    "Regular" => "Georgia.TTF",
    "Italic" => "Georgiai.TTF",
    "Bold Italic" => "Georgiaz.TTF",
    "Bold" => "Georgiab.TTF"
  })

  provides_font("Impact", match_styles_from_file: {
    "Regular" => "Impact.TTF"
  })

  provides_font("Webdings", match_styles_from_file: {
    "Regular" => "Webdings.TTF"
  })

  def extract
    resource("EUupdate.EXE") do |resource|
      cab_extract(resource) do |dir|
        match_fonts(dir, "Arial")
        match_fonts(dir, "Trebuchet")
        match_fonts(dir, "Verdana")
        match_fonts(dir, "Times New Roman")
      end
    end

    resource "andale32.exe" do |resource|
      cab_extract(resource) do |dir|
        match_fonts(dir, "Andale Mono")
      end
    end

    resource "arialb32.exe" do |resource|
      cab_extract(resource) do |dir|
        match_fonts(dir, "Arial Black")
      end
    end

    resource "comic32.exe" do |resource|
      cab_extract(resource) do |dir|
        match_fonts(dir, "Comic Sans")
      end
    end

    resource "courie32.exe" do |resource|
      cab_extract(resource) do |dir|
        match_fonts(dir, "Courier")
      end
    end

    resource "georgi32.exe" do |resource|
      cab_extract(resource) do |dir|
        match_fonts(dir, "Georgia")
      end
    end

    resource "impact32.exe" do |resource|
      cab_extract(resource) do |dir|
        match_fonts(dir, "Impact")
      end
    end

    resource "webdin32.exe" do |resource|
      cab_extract(resource) do |dir|
        match_fonts(dir, "Webdings")
      end
    end

  end

  def install
    case platform
    when :macos
      install_matched_fonts "$HOME/Library/Fonts/Microsoft"
    when :linux
      install_matched_fonts "/usr/share/fonts/truetype/vista"
    end
  end

  test do
    case platform
    when :macos
      assert_predicate "$HOME/Library/Fonts/Microsoft/cour.ttf", :exist?
    when :linux
      assert_predicate "/usr/share/fonts/truetype/vista/cour.ttf", :exist?
    end
  end

end
