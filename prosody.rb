require "formula"

class Prosody < Formula
  homepage "http://prosody.im"

  url "https://prosody.im/downloads/source/prosody-0.9.14.tar.gz"
  sha256 "27d1388acd79eaa453f2b194bd23c25121fe0a704d0dd940457caf1874ea1123"
  version "0.9.14"

  depends_on "lua@5.1"
  depends_on "expat"
  depends_on "libidn"
  depends_on "openssl"
  depends_on "luarocks"

  def install
    # Install to the Cellar, but direct modules to prefix
    # Specify where the Lua is to avoid accidental conflict.
    lua_prefix = Formula["lua@5.1"].opt_prefix
    openssl = Formula["openssl"]
    expat = Formula["expat"]

    # set CFLAGS/LDFLAGS based on host OS (for shared libraries)
    if OS.linux?
        cflags = "-fPIC -I#{openssl.opt_include}"
        ldflags = "-shared -L#{openssl.opt_lib}"
    else
        cflags = "-I#{openssl.opt_include}"
        ldflags = "-bundle -undefined dynamic_lookup -L#{openssl.opt_lib}"
    end

    args = ["--prefix=#{prefix}",
            "--sysconfdir=#{etc}/prosody",
            "--datadir=#{var}/lib/prosody",
            "--with-lua=#{lua_prefix}",
            "--with-lua-include=#{lua_prefix}/include/lua5.1",
            "--runwith=lua5.1",
            "--cflags=#{cflags}",
            "--ldflags=#{ldflags}"]

    system "./configure", *args
    system "make"

    # patch config
    inreplace 'prosody.cfg.lua.install' do |s|
      s.sub! '--"posix";', '"posix";'
      s.sub! 'info = "prosody.log";', "-- info = \"#{var}/log/prosody/prosody.log\";"
      s.sub! 'error = "prosody.err";', "-- error = \"#{var}/log/prosody/prosody.err\";"
      # s.sub! '-- "*syslog";', '"*syslog";'
      s.sub! '-- "*console";', '"*console";'
      s.sub! '----------- Virtual hosts -----------', "daemonize=false\n\n----------- Virtual hosts -----------"
      # pid
    end

    system "luarocks", "install", "--tree=#{prefix}", "--lua-version=5.1", "luafilesystem"
    system "luarocks", "install", "--tree=#{prefix}", "--lua-version=5.1", "luasocket"
    system "luarocks", "install", "--tree=#{prefix}", "--lua-version=5.1", "luasec", "OPENSSL_DIR=#{openssl.opt_prefix}"
    system "luarocks", "install", "--tree=#{prefix}", "--lua-version=5.1", "luaexpat", "EXPAT_DIR=#{expat.opt_prefix}"
    system "luarocks", "install", "--tree=#{prefix}", "--lua-version=5.1", "bit32"

    (etc+"prosody").mkpath
    (var+"lib/prosody").mkpath
    (var+"run/prosody").mkpath
    (var+"log/prosody").mkpath

    system "make", "install"
    cd "tools/migration" do
      system "make", "install"
    end

  end

  # TODO more detailed
  def caveats; <<~EOS
    Prosody configs in: #{etc}/prosody

    EOS
  end

  test do
    system "#{bin}/prosodyctl", "about"
  end
end

# external_deps_dirs = { "/usr/local/opt/openssl" }
