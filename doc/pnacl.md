# PNaCl

This document's purpose is to inform individuals on the features, functions, and
idiosyncrasies of VLC on the PNaCl platform (or at least, those avalible at time
of writing). Additionally, this document, uhm, documents how to build VLC for
PNaCl.

Building on Windows will likely be impossible without use of MSYS. The author
uses Linux, and while an effort by the author was taken to ensure the most
platform independent instructions, the reader's mileage my vary if their
platform is not Linux. Fortunately, Linux is free and so is VirtualBox (and
PNaCl is platform/arch independent by design).

## The Build

### Prerequisites

Before we can get started, we need to procure a few things from the Internet:

 * From the NaCl SDK, pepper_43 or newer.
 * [naclports][]

To make things easier, set the environment variable `NACL_SDK_ROOT` to the
directory were you have pepper installed; for example the author of this
document uses:

```export NACL_SDK_ROOT=/opt/nacl_sdk/pepper_43```

#### Setting up needed packages from `naclports`.

From the checkout directory of `naclports` (note: needs `NACL_SDK_ROOT`): ```bin/naclports --toolchain pnacl
install libtheora libvorbis zlib ffmpeg libogg flac libpng x264 lame freetype
fontconfig libxml2 libarchive mpg123 libmodplug protobuf faad2 libebml
libmatroska```

Note: `libav` won't work in place of `ffmpeg`.

The author recommends getting a cup of coffee as the above is running: it will
take a while, especially if one doesn't use `naclports`' continuous builders
(actually using the continuous builders is left as an exercise for the reader).

#### GL ES 2

Somewhat annoyingly, support of OpenGL ES 2 isn't recognized unless a curtain
`pkg-config` file is present. From VLC's source root, run:
```cp ./extras/ppapi/glesv2.pc $(dirname $NACL_SDK_ROOT/tools/nacl_config.py -t
pnacl --tool cc)/../le32-nacl/usr/lib/pkgconfig```

### Configure

There are quite a few modules that just don't make sense in a program compiled
to run inside a web browser. For example, `httpd`, `ncurses`, `bonjour`, `upnp`,
`qt`, etc. Some others are disabled because there is currently no way to use
them, for example `lua`, `skins2`. First we need to bootstrap VLC:

```./bootstrap```

Now we can `configure` (note you should probably do this in a different
directory from the source, ie an out-of-tree build):

```RANLIB="$($NACL_SDK_ROOT/tools/nacl_config.py -t pnacl --tool ranlib)" \
AR="$($NACL_SDK_ROOT/tools/nacl_config.py -t pnacl --tool ar)" \
LD="$($NACL_SDK_ROOT/tools/nacl_config.py -t pnacl --tool ld)" \
CXX="$($NACL_SDK_ROOT/tools/nacl_config.py -t pnacl --tool c++)" \
CC="$($NACL_SDK_ROOT/tools/nacl_config.py -t pnacl --tool cc)" \
LDFLAGS="-L$NACL_SDK_ROOT/lib/pnacl/Release" \
CFLAGS="-I$NACL_SDK_ROOT/include/pnacl -I$NACL_SDK_ROOT/include -I$NACL_SDK_ROOT/toolchain/$($NACL_SDK_ROOT/tools/getos.py)_pnacl/le32-nacl/usr/include -I$NACL_SDK_ROOT/toolchain/$($NACL_SDK_ROOT/tools/getos.py)_pnacl/le32-nacl/usr/include/glibc-compat -ffp-contract=off" \
CXXFLAGS="-I$NACL_SDK_ROOT/include/pnacl -I$NACL_SDK_ROOT/include -I$NACL_SDK_ROOT/toolchain/$($NACL_SDK_ROOT/tools/getos.py)_pnacl/le32-nacl/usr/include -I$NACL_SDK_ROOT/toolchain/$($NACL_SDK_ROOT/tools/getos.py)_pnacl/le32-nacl/usr/include/glibc-compat -ffp-contract=off" \
PKG_CONFIG_LIBDIR=$NACL_SDK_ROOT/toolchain/$($NACL_SDK_ROOT/tools/getos.py)_pnacl/le32-nacl/usr/lib/pkgconfig \
./configure --host=le32-unknown-nacl --target=le32-unknown-nacl --disable-shared \
--enable-static --enable-vlc --disable-a52 --enable-gles2 --disable-xcb \
--disable-xvideo --disable-libgcrypt --disable-lua --disable-vlm --disable-sout \
--disable-addonmanagermodules --disable-httpd --disable-alsa --disable-pulse \
--disable-svg --disable-svgdec --disable-ncurses --disable-shout \
--disable-gnutls --disable-screen --disable-bonjour --disable-dbus \
--disable-udev --disable-upnp --disable-goom --disable-projectm --disable-mtp \
--disable-vsxu -disable-qt --disable-skins2 --disable-vdpau --disable-vda \
--without-contrib --disable-aribsub --enable-optimized```

### Building

As a result of taking the address of `memcpy` somewhere && LLVM/Clang, we can't directly use the
built `vlc-static`.

The author uses the following script from the build dir for building (it assumes
`NACL_SDK_ROOT` is set):

    #/bin/sh
    PWD=`pwd`;
    NACL_OS=`$NACL_SDK_ROOT/tools/getos.py`;

    if [ -e "/usr/bin/remake" ];
    then
        MAKE=remake
    else
        MAKE=make
    fi

    $MAKE -C $PWD -j `nproc` || exit 1;

    if [ $PWD/bin/vlc-static -nt $PWD/bin/vlc-static.pexe ] || [ ! -e $PWD/bin/vlc-static.pexe ];
    then
        ($NACL_SDK_ROOT/toolchain/${NACL_OS}_pnacl/bin/pnacl-opt -S $PWD/bin/vlc-static | sed s/@memcpy/@__memcpy/g | $NACL_SDK_ROOT/toolchain/${NACL_OS}_pnacl/bin/pnacl-opt - -o $PWD/bin/vlc-static.debug.pexe) || exit 1
        $NACL_SDK_ROOT/toolchain/${NACL_OS}_pnacl/bin/pnacl-strip $PWD/bin/vlc-static.debug.pexe -o $PWD/bin/vlc-static.pexe && $NACL_SDK_ROOT/toolchain/${NACL_OS}_pnacl/bin/pnacl-freeze $PWD/bin/vlc-static.pexe -o $PWD/bin/vlc-static.pexe.tmp && $NACL_SDK_ROOT/toolchain/${NACL_OS}_pnacl/bin/pnacl-bccompress $PWD/bin/vlc-static.pexe.tmp -o $PWD/bin/vlc-static.pexe && rm $PWD/bin/vlc-static.pexe.tmp

        echo Translating...

        $NACL_SDK_ROOT/toolchain/${NACL_OS}_pnacl/bin/pnacl-translate $PWD/bin/vlc-static.debug.pexe -o $PWD/bin/vlc-static.debug.nexe -arch x86_64 --allow-llvm-bitcode-input -O0 -threads=auto
    fi

### Correcting for disabled modules (if you get undefined 'vlc_module_...' errors)

Because VLC uses modules for most of it's functions, we have to update the
static module list so `vlc-static` doesn't try to reference/initialize modules
that aren't actually present. There's a script to detect this, just run
`gen_static_modules.sh` from the `bin` subdirectory like so (where `$VLC_BUILD`
points to the build dir):

    ./gen_static_modules.sh vlc_ppapi_static_modules_init.h vlc_ppapi_static_ldadd.am $VLC_BUILD

Then rebuild.

# Embedding VLC

    <script async>
        var getVlc = null;
	    var restartVlc = null;
        (function() {
            "use strict";

            var embed = null;
	        var parent = document.getElementById('video');

	        restartVlc = function() {
                if(embed != null) {
	                parent.removeChild(embed);
	            }

                embed = document.createElement('embed');
                embed.setAttribute('id', 'vlc');
	            embed.setAttribute('src', 'vlc-debug.nmf');
	            embed.setAttribute('type', 'application/x-nacl');
                // Comment out the following two lines if debugging VLC
                embed.setAttribute('src', 'vlc-release.nmf');
                embed.setAttribute('type', 'application/x-pnacl');
                embed.setAttribute('width', '100%');
                embed.setAttribute('height', '100%');

                embed.addEventListener('load', function() {
	                var instance = new VlcInstance(embed);
                    getVlc = function() {
	                    return instance;
	                };
                });
                parent.appendChild(embed);
	       };
	       restartVlc();
       })();
    </script>

Place the above after the #video element. It will create a single VLC
instance. Call `restartVlc()` to restart the instance. `getVlc()` will return
the instance object. Info on the API present is documented below.

Additionally, `extra/ppapi/ppapi-control.js` should be included in the `<head>` of
the HTML document. `ppapi-control.js` is internally versioned (ie all messages
sent to VLC specify which API version to use), so it is safe to copy where ever
needed.

Consult the [nmf documentation][] for info on how to create `vlc-debug.nmf` and
`vlc-release.nmf`.

[nmf documentation]: https://developer.chrome.com/native-client/reference/nacl-manifest-format


# Using the Javascript API

Using `getVlc()` from above (all of these are static, in the C++ class sense):

 * `getVlc().input` -- Stuff apropos to the current input (as defined in
 `libvlccore`).
   - `getVlc().input.state` -- Access to the backend `input_thread_t`
     state. Mostly for debugging; use `getVlc().playlist.state` instead.
   - `getVlc().input.rate` -- Get or set the current playback rate. Must be
   positive.
   - `getVlc().input.item` -- Get the currently playing item or `undefined` if
   nothing is playing.
   - `getVlc().input.position` -- Get or set the current position of the
   media. Range: [0.0f, 1.0f]. Float.
   - `getVlc().input.time` -- Get or set the current time index of the
   media. Array [seconds, nanoseconds].
   - `getVlc().input.length` -- Get the length of the currently playing
     item. Array [seconds, nanoseconds].
   - `getVlc().input.video` -- Stuff relevant to videos only.
     * `getVlc().input.video.nextFrame()` -- Pause media and display next
     frame.
     * `getVlc().input.video.prevFrame()` -- Pause media and display previous
     frame. MASSIVELY slow. Won't function correctly without precise indexes.
 * `getVlc().playlist` -- Stuff apropos to the playlist.
   - `getVlc().playlist.audio` -- Stuff relevant to videos only (the volume
     level is manage via playlist interfaces, so the author put it here).
     * `getVlc().playlist.audio.muted` -- Get or set the mute toggle. Boolean.
     * `getVlc().playlist.audio.volume` -- Get or set the audio volume. Values >
     1.0f will result in amplification. Float.
   - `getVlc().playlist.clear()` -- Clear all items from the playlist.
   - `getVlc().playlist.enqueue()` -- Add item(s) to the playlist. Accepts a
   single URL or an array of URLs. URLs must be absolute and prefixed with
   `http://`.
   - `getVlc().playlist.dequeue()` -- Remove item(s) from the playlist. Accepts
   a single `playlist_item_id` or an array of them. `playlist_item_id` can be
   found in an element of `getVlc().playlist.items`.
   - `getVlc().playlist.items` -- Gets the list of items in the playlist.
   - `getVlc().playlist.next()` -- Stop playing the current item and set the
   current item to the next in the playlist.
   - `getVlc().playlist.prev()` -- Stop playing the current item and set the
   current item to the prev in the playlist.
   - `getVlc().playlist.play()` -- Start playlist playback.
   - `getVlc().playlist.pause()` -- Pause playback.
   - `getVlc().playlist.stop()` -- Stop playlist playback. Does not reset the
   playlist to the beginning.
   - `getVlc().playlist.status` -- Get the current playback status. Will be one
   of `getVlc().playlist.STOPPED_STATUS`, `getVlc().playlist.RUNNING_STATUS`, or
   `getVlc().playlist.PAUSED_STATUS`. Convenience functions are
   `getVlc().playlist.isStopped()`, `getVlc().playlist.isRunning()`, and
   `getVlc().playlist.isPaused()`, respectively.
   - `getVlc().playlist.repeating` -- If true, repeat the current item.
   - `getVlc().playlist.looping` -- If true, repeat the whole playlist.
 * `getVlc().sys` -- Stuff related to VLC under the hood.
   - `getVlc().sys.log_level` -- Get or set log filtering level. Range: [0, 4].
   - `getVlc().sys.version` -- Get an object with various details about version
   of the VLC instance.
   - `getVlc().sys.purge_cache()` -- Purge `ppapi-access`' media cache. All or
     nothing.

Note: `getVlc().this_is_a_method()` && `getVlc().this_is_a_property`. All
methods accept a callback parameter as the last argument. The callback will be
called asynchronously with the results. Status codes mimic HTTP status codes, ie
a `return_code` with a value of `200` indicates success. If no callback is
provided, any and all errors will be ignored with a warning printed to the
devtools console.


There is a limited selection of event one can listen for on the `playlist` and
`input` objects. Add a callback listener by calling `addEventListener(loc, callback)` and
remove it with `removeEventCallback(loc, callback)` on the object.

`playlist` events (new values are in the `new_value` key, old in `old_value`):

 * `input-current`: signals when the playlist input thread object (and thus the
  item) has changed. If the value is 0, the input was stopped and removed.

`input` events (new values are in the `value` key):

 * `state` -- integer.
 * `dead` -- no value.
 * `rate` -- See `getVlc().input.rate`.
 * `position` -- See `getVlc().input.position`.
 * `length` -- See `getVlc().input.length`.
 * `chapter` -- no value.
 * `program` -- no value.
 * `es` -- no value.
 * `teletext` -- no value.
 * `record` -- no value.
 * `item-meta` -- See `getVlc().input.item`.
 * `item-info` -- no value.
 * `item-name` -- no value.
 * `item-epg` -- no value.
 * `statistics` -- no value.
 * `signal` -- no value.
 * `audio-delay` -- no value.
 * `subtitle-delay` -- no value.
 * `bookmark` -- no value.
 * `cache` -- Double, % buffered.
 * `aout` -- no value.
 * `vout` -- no value.

Example: `getVlc().input.addEventListener('position', function(event) { console.log(event); }`

This JS API is fully versioned, so the included `ppapi-control.js` can be copied
into your projects source control and updated only when desired.

Take a look at `ppapi-control.js` in `extras/ppapi/ppapi-control.js` for more info.

## Issues

 * XXX: There are no unit tests!
 * The author hasn't extensively tested `ppapi-access.cpp` on slow connections (ie
   not localhost).
 * NaCl's service runtime/IRT doesn't support clock selection (though getting
   the monotonic time is still possible). Currently, vlc translates absolute
   monotonic time into absolute realtime time when waiting on condition vars.
 * Something takes the address of `memcpy` (which is technically undefined
   behaviour). However, Clang doesn't error on this, and instead inserts a
   wrapper named exactly `memcpy`. LLVM then overwrites the real version of
   memcpy (ie what calls to @llvm.memcpy turn into) with the wrapper that Clang
   inserted, resulting in a infinite loop/stack exhaustion. The author uses this
   script to fix:
   ```sh
   $NACL_SDK_ROOT/toolchain/`$NACL_SDK_ROOT/tools/getos.py`_pnacl/bin/pnacl-opt -S $PWD/bin/vlc-static | sed 's/@memcpy/@__memcpy/g' | $NACL_SDK_ROOT/toolchain/`$NACL_SDK_ROOT/tools/getos.py`_pnacl/bin/pnacl-opt - -o $PWD/bin/vlc-static.debug.pexe
   ```
 * Although code to manage multiple simultaneous instances is present, the
   author has not tested any of it in any capacity.
 * Use `PPB_VideoDecoder` to decode videos. This will delegate decoding to
   hardware, and should greatly reduce the CPU usage of many videos.

[naclports]: https://code.google.com/p/naclports/wiki/HowTo_Checkout
