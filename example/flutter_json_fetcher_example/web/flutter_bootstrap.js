var loading = document.querySelector('#loading');

{{flutter_js}}

{{flutter_build_config}}

// Load the Flutter engine
_flutter.loader.load({
    onEntrypointLoaded: async function(engineInitializer) {
        loading.classList.add('main_done');

        // Initialize the Flutter engine.
        const appRunner = await engineInitializer.initializeEngine();

        loading.classList.add('init_done');

        // Run the Flutter app.
        await appRunner.runApp();

        // Wait a few milliseconds so users can see the "zoooom" animation
        // before getting rid of the "loading" div.
        window.setTimeout(function() {
          loading.remove();
        }, 200);
    },
    serviceWorkerSettings: {
        serviceWorkerVersion: {{flutter_service_worker_version}},
    },
});