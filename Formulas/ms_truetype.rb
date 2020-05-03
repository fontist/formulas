class MsTruetypeFonts < FontFormula

  desc "Microsoft TrueType Core fonts for the Web"
  homepage "https://www.microsoft.com"

  resource "EUupdate.EXE" do
    url "https://nchc.dl.sourceforge.net/project/corefonts/the%20fonts/final/EUupdate.EXE"
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
    url "https://nchc.dl.sourceforge.net/project/corefonts/the%20fonts/final/andale32.exe"
    sha256 "0524fe42951adc3a7eb870e32f0920313c71f170c859b5f770d82b4ee111e970"
  end

  resource "comic32.exe" do
    url "https://nchc.dl.sourceforge.net/project/corefonts/the%20fonts/final/comic32.exe"
    sha256 "9c6df3feefde26d4e41d4a4fe5db2a89f9123a772594d7f59afd062625cd204e"
  end

  resource "courie32.exe" do
    url "https://nchc.dl.sourceforge.net/project/corefonts/the%20fonts/final/courie32.exe"
    sha256 "bb511d861655dde879ae552eb86b134d6fae67cb58502e6ff73ec5d9151f3384"
  end

  resource "georgi32.exe" do
    url "https://nchc.dl.sourceforge.net/project/corefonts/the%20fonts/final/georgi32.exe"
    sha256 "2c2c7dcda6606ea5cf08918fb7cd3f3359e9e84338dc690013f20cd42e930301"
  end

  resource "impact32.exe" do
    url "https://nchc.dl.sourceforge.net/project/corefonts/the%20fonts/final/impact32.exe"
    sha256 "6061ef3b7401d9642f5dfdb5f2b376aa14663f6275e60a51207ad4facf2fccfb"
  end

  resource "webdin32.exe" do
    url "https://nchc.dl.sourceforge.net/project/corefonts/the%20fonts/final/webdin32.exe"
    sha256 "64595b5abc1080fba8610c5c34fab5863408e806aafe84653ca8575bed17d75a"
  end

  provides_font("Andale Mono", match_styles_from_file: {
    "Regular" => "AndaleMo.TTF"
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
        match_fonts(dir, "Wingdings")
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
      assert_predicate "$HOME/Library/Fonts/Microsoft/candarab.ttf", :exist?
    when :linux
      assert_predicate "/usr/share/fonts/truetype/vista/candarab.ttf", :exist?
    end
  end

  requires_license_agreement <<~EOS
  MICROSOFT SOFTWARE LICENSE TERMS
  MICROSOFT POWERPOINT VIEWER
  These license terms are an agreement between Microsoft Corporation (or based on where you live, one of its affiliates) and you. Please read them. They apply to the software named above, which includes the media on which you received it, if any. The terms also apply to any Microsoft
  "  updates,
  "  supplements,
  "  Internet-based services, and
  "  support services
  for this software, unless other terms accompany those items. If so, those terms apply.
  BY USING THE SOFTWARE, YOU ACCEPT THESE TERMS. IF YOU DO NOT ACCEPT THEM, DO NOT USE THE SOFTWARE.
  If you comply with these license terms, you have the rights below.
  1.	INSTALLATION AND USE RIGHTS.
  a.	General. You may install and use any number of copies of the software on your devices. You may use the software only to view and print files created with Microsoft Office software. You may not use the software for any other purpose.
  b.	Distribution. You may copy and distribute the software, provided that:
  "  each copy is complete and unmodified, including presentation of this agreement for each user's acceptance; and
  "  you indemnify, defend, and hold harmless Microsoft and its affiliates and suppliers from any claims, including attorneys  fees, related to your distribution of the software.
  You may not:
  "  distribute the software with any non-Microsoft software that may use the software to enhance its functionality,
  "  alter any copyright, trademark or patent notices in the software,
  "  use Microsoft s or affiliates or suppliers  name, logo or trademarks to market your products or services,
  "  distribute the software with malicious, deceptive or unlawful programs, or
  "  modify or distribute the software so that any part of it becomes subject to an Excluded License. An Excluded License is one that requires, as a condition of use, modification or distribution, that
  "  the code be disclosed or distributed in source code form; or
  "  others have the right to modify it.
  2.	SCOPE OF LICENSE. The software is licensed, not sold. This agreement only gives you some rights to use the software. Microsoft reserves all other rights. Unless applicable law gives you more rights despite this limitation, you may use the software only as expressly permitted in this agreement. In doing so, you must comply with any technical limitations in the software that only allow you to use it in certain ways. You may not
  "  work around any technical limitations in the software;
  "  reverse engineer, decompile or disassemble the software, except and only to the extent that applicable law expressly permits, despite this limitation;
  "  make more copies of the software than specified in this agreement or allowed by applicable law, despite this limitation;
  "  publish the software for others to copy;
  "  rent, lease or lend the software; or
  "  use the software for commercial software hosting services.
  3.	BACKUP COPY. You may make one backup copy of the software. You may use it only to reinstall the software.
  4.	FONT COMPONENTS. While the software is running, you may use its fonts to display and print content. You may only
  "  embed fonts in content as permitted by the embedding restrictions in the fonts; and
  "  temporarily download them to a printer or other output device to print content.
  5.	DOCUMENTATION. Any person that has valid access to your computer or internal network may copy and use the documentation for your internal, reference purposes.
  6.	TRANSFER TO ANOTHER DEVICE. You may uninstall the software and install it on another device for your use. You may not do so to share this license between devices.
  7.	TRANSFER TO A THIRD PARTY. The first user of the software may transfer it and this agreement directly to a third party. Before the transfer, that party must agree that this agreement applies to the transfer and use of the software. The first user must uninstall the software before transferring it separately from the device. The first user may not retain any copies.
  8.	EXPORT RESTRICTIONS. The software is subject to United States export laws and regulations. You must comply with all domestic and international export laws and regulations that apply to the software. These laws include restrictions on destinations, end users and end use. For additional information, see www.microsoft.com/exporting.
  9.	SUPPORT SERVICES. Because this software is  as is,  we may not provide support services for it.
  10.	ENTIRE AGREEMENT. This agreement, and the terms for supplements, updates, Internet-based services and support services that you use, are the entire agreement for the software and support services.
  11.	APPLICABLE LAW.
  a.	United States. If you acquired the software in the United States, Washington state law governs the interpretation of this agreement and applies to claims for breach of it, regardless of conflict of laws principles. The laws of the state where you live govern all other claims, including claims under state consumer protection laws, unfair competition laws, and in tort.
  b.	Outside the United States. If you acquired the software in any other country, the laws of that country apply.
  12.	LEGAL EFFECT. This agreement describes certain legal rights. You may have other rights under the laws of your country. You may also have rights with respect to the party from whom you acquired the software. This agreement does not change your rights under the laws of your country if the laws of your country do not permit it to do so.
  13.	DISCLAIMER OF WARRANTY. THE SOFTWARE IS LICENSED  AS-IS.  YOU BEAR THE RISK OF USING IT. MICROSOFT GIVES NO EXPRESS WARRANTIES, GUARANTEES OR CONDITIONS. YOU MAY HAVE ADDITIONAL CONSUMER RIGHTS UNDER YOUR LOCAL LAWS WHICH THIS AGREEMENT CANNOT CHANGE. TO THE EXTENT PERMITTED UNDER YOUR LOCAL LAWS, MICROSOFT EXCLUDES THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT.
  14.	LIMITATION ON AND EXCLUSION OF REMEDIES AND DAMAGES. YOU CAN RECOVER FROM MICROSOFT AND ITS SUPPLIERS ONLY DIRECT DAMAGES UP TO U.S. $5.00. YOU CANNOT RECOVER ANY OTHER DAMAGES, INCLUDING CONSEQUENTIAL, LOST PROFITS, SPECIAL, INDIRECT OR INCIDENTAL DAMAGES.
  This limitation applies to
  "  anything related to the software, services, content (including code) on third party Internet sites, or third party programs; and
  "  claims for breach of contract, breach of warranty, guarantee or condition, strict liability, negligence, or other tort to the extent permitted by applicable law.
  It also applies even if Microsoft knew or should have known about the possibility of the damages. The above limitation or exclusion may not apply to you because your country may not allow the exclusion or limitation of incidental, consequential or other damages.
  EULAID:O14_RTM_PPV.1_RTM_EN
  EOS

end
