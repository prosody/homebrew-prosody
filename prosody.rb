require "formula"

class Prosody < Formula
  homepage "http://prosody.im"

  url "https://prosody.im/downloads/source/prosody-0.12.1.tar.gz"
  sha256 "a7ecbbe41f01a4251805593ac6d15dbc6cb75d9c7a876c76b456cf74ff4b90e5"
  version "0.12.1"

  depends_on "lua@5.4"
  depends_on "expat"
  depends_on "icu4c"
  depends_on "openssl"
  depends_on "luarocks"

  def install
    # Install to the Cellar, but direct modules to prefix
    # Specify where the Lua is to avoid accidental conflict.
    lua_prefix = Formula["lua@5.4"].opt_prefix
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
            "--with-lua-include=#{lua_prefix}/include/lua5.4",
            "--runwith=lua5.4",
            "--cflags=#{cflags}",
            "--ldflags=#{ldflags}"]

    system "./configure", *args
    system "make"

    # patch config
    inreplace 'prosody.cfg.lua.install' do |s|
      s.sub! 'info = "prosody.log";', "-- info = \"#{var}/log/prosody/prosody.log\";"
      s.sub! 'error = "prosody.err";', "-- error = \"#{var}/log/prosody/prosody.err\";"
      # s.sub! '-- "*syslog";', '"*syslog";'
      s.sub! '-- "*console";', '"*console";'
      # pid
    end

    system "luarocks", "install", "--tree=#{prefix}", "--lua-version=5.4", "luafilesystem"
    system "luarocks", "install", "--tree=#{prefix}", "--lua-version=5.4", "luasocket"
    system "luarocks", "install", "--tree=#{prefix}", "--lua-version=5.4", "luasec", "OPENSSL_DIR=#{openssl.opt_prefix}"
    system "luarocks", "install", "--tree=#{prefix}", "--lua-version=5.4", "luaexpat", "EXPAT_DIR=#{expat.opt_prefix}"

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

    Prosody may complain about LuaExpat not supporting stanza size
    limits. This is due to a situation with the version of LuaExpat
    on LuaRocks.
    See https://issues.prosody.im/1375 for further details.
    EOS
  end

  test do
    system "#{bin}/prosodyctl", "check"
  end
end

# external_deps_dirs = { "/usr/local/opt/openssl" }
