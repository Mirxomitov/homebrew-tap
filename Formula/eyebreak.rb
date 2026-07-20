# Homebrew formula for Eyebreak — a native macOS menu-bar eye-break timer.
#
#   brew install mirxomitov/tap/eyebreak
#   brew services start eyebreak      # run it now and at every login
#
# Building from source means the app is compiled on the user's own machine, so it
# needs no Developer ID signing/notarization to get past Gatekeeper.
class Eyebreak < Formula
  desc "Native menu-bar 20-20-20 eye-break timer with a full-screen break blocker"
  homepage "https://github.com/Mirxomitov/eyebreak"
  license "MIT"
  url "https://github.com/Mirxomitov/eyebreak/archive/refs/tags/v1.4.0.tar.gz"
  sha256 "b94441f616d994fbd4ec5b2b77f6a62d2721eed7a3b5b999b4f09cf60442011e"
  version "1.4.0"
  head "https://github.com/Mirxomitov/eyebreak.git", branch: "main"

  depends_on :macos

  def install
    # build.sh compiles native/Eyebreak.swift into a proper Eyebreak.app bundle
    # (Info.plist + bundle id, which the app needs for notifications).
    system "native/build.sh", "#{buildpath}/out"
    libexec.install "#{buildpath}/out/Eyebreak.app"

    # `eyebreak` launches the app via LaunchServices (or `eyebreak --quit-others`
    # style flags pass straight through to a fresh instance).
    (bin/"eyebreak").write <<~SH
      #!/bin/bash
      exec /usr/bin/open "#{opt_libexec}/Eyebreak.app" "$@"
    SH
  end

  # `brew services start eyebreak` runs the app now and at login via a
  # Homebrew-managed LaunchAgent — no manual login-item setup.
  service do
    run [opt_libexec/"Eyebreak.app/Contents/MacOS/Eyebreak"]
    keep_alive false
    log_path var/"log/eyebreak.log"
    error_log_path var/"log/eyebreak.log"
  end

  def caveats
    <<~EOS
      Start Eyebreak now and at every login:

        brew services start eyebreak

      Or launch it once (no auto-start):

        eyebreak

      Look for the 👀 icon in your menu bar. State lives in ~/.eyebreak.
    EOS
  end

  test do
    assert_path_exists libexec/"Eyebreak.app/Contents/MacOS/Eyebreak"
    # The headless stats hook must run and print a report line.
    output = shell_output("#{libexec}/Eyebreak.app/Contents/MacOS/Eyebreak --print-stats")
    assert_match "total=", output
  end
end
