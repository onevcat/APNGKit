# Change Log

All notable changes to this project will be documented in this file.

## [Unreleased]

### Add

- Support for setting a single `APNGImage` to multiple `APNGImageView`s. It lifts off the limitation in previous versions that an `APNGImage` can only be set to one `APNGImageView`. Now, it is free to be used in different image views and the image view controls the animation playing. [#124](https://github.com/onevcat/APNGKit/pull/124) @onevcat

## [2.1.2] - 2022-03-05

### Fix

- An issue that when the frame contains `APNG_DISPOSE_OP_PREVIOUS` or `APNG_DISPOSE_OP_BACKGROUND`, the output buffer does not reset in some cases. [#122](https://github.com/onevcat/APNGKit/pull/122) @onevcat

## [2.1.1] - 2021-12-15

### Fix

- An issue introduced in 2.1.0 that the background was not clear before rendering the next frame when `dispose_op` is `previous`. [#118](https://github.com/onevcat/APNGKit/pull/118) @onevcat

## [2.1.0] - 2021-12-09

### Add

- Expose the `APNGFrame` type and related properties in `APNGImage` to allow getting some basic information by frame. [#117](https://github.com/onevcat/APNGKit/pull/117) @onevcat

### Fix

- An issue that wrong area is reverted when `dispose_op` is set to `previous` and the render area is not the full canvas. [#117](https://github.com/onevcat/APNGKit/pull/117) @onevcat

## [2.0.2] - 2021-11-17

### Fix

- An issue that the PNG decoder would fail to render frames when there are image shared chunks between `acTL` and the first actual image frame. [#114](https://github.com/onevcat/APNGKit/pull/114) @onevcat

## [2.0.1] - 2021-11-02

### Fix

- Swift Package Manager now can resolve this package in Xcode. [#112](https://github.com/onevcat/APNGKit/pull/112)

## [2.0.0] - 2021-11-01

Version 2.0.0. This is not a compatible version compared to version 1.x. All code is rewritten from scratch so you may
need also check the README to do a re-implement.

[2.0.0]: https://github.com/onevcat/APNGKit/compare/1.2.3...2.0.0
[2.0.1]: https://github.com/onevcat/APNGKit/compare/2.0.0...2.0.1
[2.0.2]: https://github.com/onevcat/APNGKit/compare/2.0.1...2.0.2
[2.1.0]: https://github.com/onevcat/APNGKit/compare/2.0.2...2.1.0
[2.1.1]: https://github.com/onevcat/APNGKit/compare/2.1.0...2.1.1
[2.1.2]: https://github.com/onevcat/APNGKit/compare/2.1.1...2.1.2
