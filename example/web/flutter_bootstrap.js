{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
    onEntrypointLoaded: async function(engineInitializer) {
        // get EntrypointLoad metric
        addMetric('example_process', 'entrypointLoad');

        const appRunner = await engineInitializer.initializeEngine();
        // get FlutterEngineInit metric
        addMetric('example_process', 'flutterEngineInit');

        await appRunner.runApp();
        // get AppRun metric
        addMetric('example_process', 'appRun');
    }
});