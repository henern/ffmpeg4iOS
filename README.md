ffmpeg4iOS
==========

trying to build a full-function player, from scratch, for iOS. 
based on ffmpeg project, and some powerful capability of iOS device. 

You may need?
-------------
1. [scripts](https://github.com/henern/ffmpeg4iOS/tree/master/script) to build ffmpeg for iOS.
2. ffmpeg binary libs for [armv7](https://github.com/henern/ffmpeg4iOS/tree/master/ffmpeg4iphone-read-only/ffmpeg-libs/armv7), [arm64](https://github.com/henern/ffmpeg4iOS/tree/master/ffmpeg4iphone-read-only/ffmpeg-libs/arm64), [x86_64](https://github.com/henern/ffmpeg4iOS/tree/master/ffmpeg4iphone-read-only/ffmpeg-libs/x86_64).
3. code of latest stable ffmpeg release, it's [v2.7.1](https://github.com/henern/ffmpeg4iOS/tree/master/archive) while my last update.

Features
--------
1. version: 0.1.0.0
2. platform: iOS5/6/7/8
3. cpu: armv7 + x86_64 + arm64.
4. video: OpenGLES 2.0
5. audio: AudioQueue
6. hardware accelerator: mp3 + aac + he-aac, h264, 
7. misc: customized-user-agent, 
8. protocol: http, https, 
9. patch: EXT-X-DISCONTINUITY, 
X. coming (not that soon) ...

Samples
-------
1. a simple [demo](https://github.com/henern/ffmpeg4iOS/tree/master/test/sample)
2. coming (not that soon) ...

TODO
----
1. subtitles

License
-------
This project is licensed under the terms of the MIT license.

Dependency
----------
1. [ffmpeg](http://ffmpeg.org/download.html)
2. [gas-prepocessor](https://github.com/libav/gas-preprocessor)