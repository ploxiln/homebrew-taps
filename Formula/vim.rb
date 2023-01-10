class Vim < Formula
  desc "Vi 'workalike' with many additional features (Pierce's build)"
  homepage "https://www.vim.org/"
  # vim should only be updated every 50 releases on multiples of 50
  url "https://github.com/vim/vim/archive/v9.0.1150.tar.gz"
  sha256 "aaa03eaeb68e8ee39137c5ffb8d41b4cce58f53860724829aba6385454b98c69"
  license "Vim"
  head "https://github.com/vim/vim.git", branch: "master"

  # The Vim repository contains thousands of tags and the `Git` strategy isn't
  # ideal in this context. This is an exceptional situation, so this checks the
  # first page of tags on GitHub (to minimize data transfer).
  livecheck do
    url "https://github.com/vim/vim/tags"
    regex(%r{href=["']?[^"' >]*?/tag/v?(\d+(?:\.\d+)+)["' >]}i)
    strategy :page_match
  end

  depends_on "gettext"
  depends_on "lua"
  depends_on "ncurses"
  #depends_on "perl"
  #depends_on "python@3.11"
  #depends_on "ruby"

  conflicts_with "ex-vi",
    because: "vim and ex-vi both install bin/ex and bin/view"

  conflicts_with "macvim",
    because: "vim and macvim both install vi* binaries"

  # fixes build issue with 9.0.1150, remove after next release
  patch do
    url "https://github.com/vim/vim/commit/5bcd29b84e4dd6435177f37a544ecbf8df02412c.patch?full_index=1"
    sha256 "6d1ae23897088cc13b31ac22f268e74fa063364b7c9a892dbee32397d4d62faf"
  end

  def install
    #ENV.prepend_path "PATH", Formula["python@3.11"].opt_libexec/"bin"

    # https://github.com/Homebrew/homebrew-core/pull/1046
    ENV.delete("SDKROOT")

    # vim doesn't require any Python package, unset PYTHONPATH.
    ENV.delete("PYTHONPATH")

    # We specify HOMEBREW_PREFIX as the prefix to make vim look in the
    # the right place (HOMEBREW_PREFIX/share/vim/{vimrc,vimfiles}) for
    # system vimscript files. We specify the normal installation prefix
    # when calling "make install".
    # Homebrew will use the first suitable Perl & Ruby in your PATH if you
    # build from source. Please don't attempt to hardcode either.
    system "./configure", "--prefix=#{HOMEBREW_PREFIX}",
                          "--mandir=#{man}",
                          "--enable-multibyte",
                          "--with-tlib=ncurses",
                          "--with-compiledby=Homebrew",
                          "--enable-cscope",
                          "--enable-terminal",
                          #"--enable-perlinterp",
                          #"--enable-rubyinterp",
                          #"--enable-python3interp",
                          "--disable-gui",
                          "--without-x",
                          "--enable-luainterp",
                          "--with-lua-prefix=#{Formula["lua"].opt_prefix}"
    system "make"
    # Parallel install could miss some symlinks
    # https://github.com/vim/vim/issues/1031
    ENV.deparallelize
    # If stripping the binaries is enabled, vim will segfault with
    # statically-linked interpreters like ruby
    # https://github.com/vim/vim/issues/114
    system "make", "install", "prefix=#{prefix}", "STRIP=#{which "true"}"
    bin.install_symlink "vim" => "vi"
  end

  test do
    #(testpath/"commands.vim").write <<~EOS
    #  :python3 import vim; vim.current.buffer[0] = 'hello python3'
    #  :wq
    #EOS
    #system bin/"vim", "-T", "dumb", "-s", "commands.vim", "test.txt"
    #assert_equal "hello python3", File.read("test.txt").chomp
    assert_match "+gettext", shell_output("#{bin}/vim --version")
  end
end
