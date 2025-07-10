class Wifiwatcher < Formula
  desc "Monitor Wi-Fi network changes and execute scripts"
  homepage "https://github.com/ramanaraj7/wifiwatcher"
  url "https://github.com/ramanaraj7/wifiwatcher/archive/refs/tags/v1.0.1.tar.gz"
  sha256 "1dae9dcc0c276078818132ca76b5745e09751ba87f12a53bd68163516f067d47"
  license "MIT"
  
  depends_on :macos

  def install
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