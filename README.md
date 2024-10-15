# measure_startup_time

`measure_startup_time` helps you measure and record startup time metrics of Flutter web apps.

> The startup time refers to the time it takes for the app to become visible to users.

In Flutter, you can write benchmark tests to measure and track the app's performance metrics such as track jank, startup time, etc. However, recording performance timelines isn't supported on web, you have to use the browser's DevTools and emit your own events.

The `measure_startup_time` package was created to provide a more convenient way to record and use startup time metrics.

## Features

You can use this package for your Flutter web app to:

- Access common performance metrics of a web app.
- Record performance metrics related to Flutter web app initialization.
- Measure the time of user-emitted events.

## Supported metrics

`measure_startup_time` package helps you measure below performance metrics during the initialization of a Flutter web.

### Common metrics

A normal web app has these common metrics:

- **DOMContentLoad - DCL**: time when the HTML document has been completely parsed, and all deferred scripts have downloaded and executed. It doesn't wait for other things like images, subframes, and async scripts to finish loading.

- **Load - L**: time when the whole page has loaded, including all dependent resources such as stylesheets, scripts, iframes, and images.

- **FirstPaint - FP**: time between navigation and when the browser first renders pixels to the screen, rendering anything that is visually different from the default background color of the body.

- **FirstContentfulPaint - FCP**: time between navigation and when any part of the page's content is rendered on the screen. For this metric, "content" refers to text, images (including background images), `<svg>` elements, or non-white `<canvas>` elements.

  _In Flutter, this metric can be affected by any elements added into load event. These elements reduce the FCP time while no contentful widget has been rendered._

- **LargestContentfulPaint - LCP**: the render time of the largest image or text block visible in the viewport, relative to when the user first navigates to the page.

### Flutter metrics

During Flutter web app initialization, you can track these metrics:

- **EntrypointLoad**: time when the service worker is initialized and the main.dart.js entrypoint has been downloaded and run by the browser.

- **FlutterEngineInit**: time when downloading required resources such as assets, fonts, and CanvasKit.

- **CanvaskitJSLoad**: time when the canvaskit.js file has been completely downloaded.

- **CanvaskitWasmLoad**: time when the canvaskit.wasm file has been completely downloaded.

- **AppRun**: time when preparing the DOM for Flutter app and running it.

### Custom metrics

In addition to above metrics, you can emit custom metrics to measure time such as image load time, data fetching time, deferred loading time, etc.

## Usage

To begin a measurement process, access the `MeasureStartupTime` object and invoke the `startMeasure` method, providing the desired process name as an argument.

```dart
const exampleProcess = 'example_process';

void main() {
  MeasureStartupTime.startMeasure(exampleProcess);
  runApp(const MyApp());
}
```

### Common metrics

Common performance metrics are measured automatically, while others are only measured upon your request.

### Flutter metrics

Flutter metrics are recorded using the `addMetric` method with a process name and metric name parameters, and an event name in the format `<process>: <metric>`.

```js
// Add these line in your head section of index.html file
<script>
  function addMetric(process, metric) {
    window.performance.measure(
      process + ': ' + metric,
      {
        detail: metric,
        start: 0,
      }
    )
  }
</script>
```

When using Flutter metrics, you call this method and combine with related callbacks:

```js
<body>
  <script>
    window.addEventListener('load', function(ev) {
      // Download main.dart.js
      _flutter.loader.loadEntrypoint({
        serviceWorker: {
          serviceWorkerVersion: serviceWorkerVersion,
        }
      }).then(function (engineInitializer) {
        // get EntrypointLoad metric
        addMetric('example_process', 'entrypointLoad');
        return engineInitializer.initializeEngine();
      }).then(function (appRunner) {
        // get FlutterEngineInit metric
        addMetric('example_process', 'flutterEngineInit');
        return appRunner.runApp();
      }).then(function (app) {
        // get AppRun metric
        addMetric('example_process', 'appRun');
      });
    });
  </script>
</body>
```

```js
<head>
  // get canvaskitJSLoad metric
  <link rel="preload" href="https://www.gstatic.com/flutter-canvaskit/f40e976bedff57e69e1b3d89a7c2a3c617a03dad/chromium/canvaskit.js" as="script" crossorigin="anonymous" onload="addMetric('example_process', 'canvaskitJSLoad')">

  // get canvaskitWasmLoad metric
  <link rel="preload" href="https://www.gstatic.com/flutter-canvaskit/f40e976bedff57e69e1b3d89a7c2a3c617a03dad/chromium/canvaskit.wasm" as="fetch" crossorigin="anonymous" onload="addMetric('example_process', 'canvaskitWasmLoad')">
</head>
```

### Custom metrics

With custom metrics emitted from the native web, invoke the `addMetric` method in `index.html` file; and with custom metrics emitted from Flutter, invoke the `measure` method of the `MeasureStartupTime` object, providing the target process and metric names.

```dart
MeasureStartupTime.measure(
    process: exampleProcess,
    metric: 'fetch_data_start',
);
```

To finish the measure running process, call `finishMeasure` method.

```dart
MeasureStartupTime.finishMeasure(exampleProcess);
```

## Results

Performance metrics are returned as a `Stream<MeasurePerformance>` object. Each metric is continuously returned as soon as it's measured, except for custom metrics that are emitted after calling `finishMeasure` method.

```dart
return StreamBuilder(
    stream: MeasureStartupTime.getMetrics(exampleProcess),
    builder: (context, metricSnapshot) {
        final metrics = metricSnapshot.data?.metrics.toList();

        return Padding(
            padding: const EdgeInsets.all(16),
            child: CustomScrollView(
                slivers: [
                    if (metrics != null) ...[
                        SliverToBoxAdapter(
                            child: Text(
                                'Metrics',
                                style: Theme.of(context).textTheme.titleLarge,
                            ),
                        ),
                        SliverList.separated(
                            itemCount: metrics.length,
                            separatorBuilder: (context, index) => const Divider(),
                            itemBuilder: (context, index) {
                                final metric = metrics[index];
                                return ListTile(
                                    title: Text(
                                        metric.name,
                                        style:
                                            const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text('${metric.duration}ms'),
                                );
                            },
                        ),
                    ],
                ],
            ),
        );
    },
);
```

## Contributing

Thanks for your interest in contributing! There are many ways to contribute to this project. Get started [here](/CONTRIBUTING.md)

## License

This package is available under [BSD-3-Clause](/LICENSE), meaning you are free to use, modify, and distribute this code.
