class Hledger < Formula
  desc "Easy plain text accounting with command-line, terminal and web UIs"
  homepage "https://hledger.org/"
  url "https://hackage.haskell.org/package/hledger-1.17.1.1/hledger-1.17.1.1.tar.gz"
  sha256 "e4ab35521591daa61fa81587e70d5a8053719749dc309cdb39714d6e3b79879d"

  bottle do
    cellar :any_skip_relocation
    rebuild 1
    sha256 "caa8cfd28bddaa3bc00745e552724e2c1086e4819976c1ef405e08d0d58f87aa" => :catalina
    sha256 "020080275f37fea9056f4cdf1258f93bfaca3ae9e7dc2f055064aad7916212c5" => :mojave
    sha256 "beb4d93eb15db9884bea31d78b729030be3d19864b7048d7baf11c12f34e40f8" => :high_sierra
  end

  depends_on "ghc@8.8" => :build
  depends_on "haskell-stack" => :build

  uses_from_macos "ncurses"
  uses_from_macos "zlib"

  resource "hledger-lib" do
    url "https://hackage.haskell.org/package/hledger-lib-1.17.1/hledger-lib-1.17.1.tar.gz"
    sha256 "4ca488f742d3d3ceee6c68cb0fb2d0531ea9fefd54c43b1d98ad102aa8f076a7"
  end
  resource "hledger-ui" do
    url "https://hackage.haskell.org/package/hledger-ui-1.17.1.1/hledger-ui-1.17.1.1.tar.gz"
    sha256 "fa7e4c0d5d073622de8d63b0883226c5dcecc39427d6ad090fbe994c3c939233"
  end
  resource "hledger-web" do
    url "https://hackage.haskell.org/package/hledger-web-1.17.1/hledger-web-1.17.1.tar.gz"
    sha256 "34cf81c6f248cda1db8b9bdbd9c14edae6422c185825ae47024b43d6913a8b7d"
  end

  def install
    (buildpath/"../hledger-lib").install resource("hledger-lib")
    (buildpath/"../hledger-ui").install resource("hledger-ui")
    (buildpath/"../hledger-web").install resource("hledger-web")
    cd ".." do
      system "stack", "update"
      system "stack", "init", "--resolver=lts-15.5"
      system "stack", "install", "--system-ghc", "--no-install-ghc", "--local-bin-path=#{bin}"

      man1.install "hledger-1.17.1.1/hledger.1"
      man1.install "hledger-ui/hledger-ui.1"
      man1.install "hledger-web/hledger-web.1"
      man5.install "hledger-lib/hledger_csv.5"
      man5.install "hledger-lib/hledger_journal.5"
      man5.install "hledger-lib/hledger_timeclock.5"
      man5.install "hledger-lib/hledger_timedot.5"

      info.install "hledger-1.17.1.1/hledger.info"
      info.install "hledger-lib/hledger_csv.info"
      info.install "hledger-lib/hledger_journal.info"
      info.install "hledger-lib/hledger_timeclock.info"
      info.install "hledger-lib/hledger_timedot.info"
      info.install "hledger-ui/hledger-ui.info"
      info.install "hledger-web/hledger-web.info"
    end
  end

  test do
    system "#{bin}/hledger", "test"

    File.open(".hledger.journal", "w") do |f|
      f.write <<~EOS
        2020/1/1
          boat  123
          cash
      EOS
    end

    system "#{bin}/hledger-ui", "--version"

    pid = fork do
      exec "#{bin}/hledger-web", "--serve"
    end
    sleep 1
    begin
      assert_match /boat +123/, shell_output("curl -s http://127.0.0.1:5000/journal")
    ensure
      Process.kill("SIGINT", pid)
      Process.wait(pid)
    end
  end
end
