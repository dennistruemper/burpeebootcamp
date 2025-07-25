const version = "v22";
const cacheName = `cache-${version}`;
const assets = [
  "/",
  "/index.html",
  "/manifest.json",
  `/styles.${version}.css`,
  "/icon/icon.svg",
  "/ios/180.png",
  "/ios/1024.png",
  "/android/android-launchericon-192-192.png",
  "/android/android-launchericon-512-512.png",
  "/logo/logo.png",
  "/logo/logo-192.png",
  "/logo/logo-512.png",
  // Add sound files to cache for offline usage
  "/sounds/rep-complete.mp3",
  "/sounds/ground-touch.mp3",
  "/sounds/workout-complete.mp3",
  "/sounds/timer-warning.mp3",
];
self.addEventListener("install", (installEvent) => {
  installEvent.waitUntil(
    caches.open(cacheName).then((cache) => {
      cache.addAll(assets);
    })
  );
});

self.addEventListener("fetch", (event) => {
  // check if request is on my domain
  if (!event.request.url.startsWith(self.location.origin)) {
    return;
  }

  event.respondWith(
    caches.open(cacheName).then((cache) => {
      // Go to the cache first
      return cache.match(event.request.url).then((cachedResponse) => {
        // Return a cached response if we have one
        if (cachedResponse) {
          return cachedResponse;
        }

        // Otherwise, hit the network
        return fetch(event.request)
          .then((fetchedResponse) => {
            console.log(fetchedResponse.status);
            // Add the network response to the cache for later visits
            cache.put(event.request, fetchedResponse.clone());

            // Return the network response
            return fetchedResponse;
          })
          .catch((err) =>
            cache.match("/").then((cached) => {
              if (cached) return cached;
            })
          );
      });
    })
  );
});
