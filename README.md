# Custom Loading Indicator

A Flutter package to display a customizable loading indicator that rotates around a specified image. The loader moves around the image's boundaries, and the transition can be smoothed using different curves.

## Features

- Customizable size for both the loader and the image.
- Ability to specify the duration of the rotation.
- Smooth transition animations using `CurvedAnimation`.
- Supports any image provider, allowing the use of assets, network images, etc.
- The loader rotates around the image without cutting it off.

## Getting Started

### Installation

Add the following to your `pubspec.yaml` file:

```yaml
dependencies:
  custom_loading_indicator: ^1.0.0
