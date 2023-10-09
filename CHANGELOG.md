# Change Log

All notable changes to this project will be documented in this file.

## [Unreleased]

## [2.2.3] - 2023-10-09

### Fix

- Use an alpha bitmap context to render images with true color (PNG ColorType 2). This allows the `tRNS` chunk to be handled correctly. [#138](https://github.com/onevcat/APNGKit/pull/138)

## [2.2.2] - 2023-05-04

### Fix

- Use `.info` log level for missing frames when decoding. This allows a better debugging experience when the image is not rendered as expected. [#129](https://github.com/onevcat/APNGKit/pull/129)
- Upgrade the project for Xcode 14.3. The deploy target version of demo app prevented it from building with Xcode 14.3. [#134](https://github.com/onevcat/APNGKit/pull/134)


## [2.2.1] - 2022-05-08

### Fix

- Wrong canvas parameter when the image header set to "true color". Now an image with non-alpha channel should be also read correctly. [#125](https://github.com/onevcat/APNGKit/pull/125) @onevcat

## [2.2.0] - 2022-03-12

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
[2.2.0]: https://github.com/onevcat/APNGKit/compare/2.1.2...2.2.0
[2.2.1]: https://github.com/onevcat/APNGKit/compare/2.2.0...2.2.1
[2.2.2]: https://github.com/onevcat/APNGKit/compare/2.2.1...2.2.2
[2.2.3]: https://github.com/onevcat/APNGKit/compare/2.2.2...2.2.3
