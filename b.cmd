echo off
cls
set LUA_PATH=%cd%/src/?.lua;%cd%/e/lib/src/?.lua;;%cd%/e/render/src/?.lua;%cd%/e/render/e/stream/src/?.lua;%cd%/e/render/e/stream/e/?.lua;%cd%/e/STL/src/?.lua;
du-lua build release --copy=release/variants/Unlimited