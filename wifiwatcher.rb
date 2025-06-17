class Wifiwatcher < Formula
  desc "Monitor Wi-Fi network changes and execute scripts"
  homepage "https://github.com/ramanaraj7/wifiwatcher"
  url "https://github.com/ramanaraj7/wifiwatcher/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "c3d2001b264e4b58f6a22ac3dd939f1f2b1673aff046f00ebd6a60bb77034d68"
  license "MIT"
  
  depends_on :macos
  depends_on xcode: :build

  def install
    system "clang", "-framework", "Foundation", "-framework", "CoreWLAN", "-fobjc-arc", "wifiwatcher.m", "-o", "wifiwatcher"
    bin.install "wifiwatcher"
    
    # Create log directory
    (var/"log").mkpath
  end

  service do
    run [opt_bin/"wifiwatcher", "--monitor"]
    keep_alive true
    log_path var/"log/wifiwatcher.log"
    error_log_path var/"log/wifiwatcher.log"
  end

  def caveats
    <<~EOS
      To complete setup, run:
        wifiwatcher --setup
      
      This creates:
      - ~/.wifiwatcher configuration file
      - Example scripts in ~/scripts/
      
      To start the service:
        brew services start wifiwatcher
      
      To stop the service:
        brew services stop wifiwatcher
    EOS
  end

  test do
    system "#{bin}/wifiwatcher", "--version"
  end
end 