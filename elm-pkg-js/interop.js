/* elm-pkg-js
port supermario_copy_to_clipboard_to_js : String -> Cmd msg
*/

const version = "v22";
const TO_JS_PORT = "toJs";
const TO_ELM_PORT = "toElm";
const SERVICE_WORKER_PATH = "/serviceWorker.js";

// Add audio context and sounds
let audioContext = null;
const sounds = {};

// Initialize audio context on first user interaction
function initAudio() {
  console.log("Initializing audio...");

  if (!audioContext) {
    console.log("Creating new audio context");
    audioContext = new (window.AudioContext || window.webkitAudioContext)();
  }

  console.log("Audio context state:", audioContext.state);

  // iOS requires the audio context to be resumed after user interaction
  if (audioContext.state === "suspended") {
    console.log("Resuming suspended audio context");
    audioContext
      .resume()
      .then(() => {
        console.log("Audio context resumed successfully");
      })
      .catch((error) => {
        console.error("Failed to resume audio context:", error);
      });
  }
}

// Load and cache sound files
async function loadSound(filename) {
  if (sounds[filename]) {
    return sounds[filename];
  }

  try {
    // Try to load from cache first, then network
    const response = await fetch(`/sounds/${filename}`);
    const arrayBuffer = await response.arrayBuffer();
    const audioBuffer = await audioContext.decodeAudioData(arrayBuffer);
    sounds[filename] = audioBuffer;
    return audioBuffer;
  } catch (error) {
    console.error("Failed to load sound:", filename, error);
    return null;
  }
}

// Play a sound with better debugging
async function playSound(filename) {
  console.log("Attempting to play sound:", filename);

  try {
    initAudio();
    console.log("Audio context state:", audioContext.state);

    const audioBuffer = await loadSound(filename);
    if (audioBuffer) {
      console.log("Audio buffer loaded successfully");
      const source = audioContext.createBufferSource();
      source.buffer = audioBuffer;
      source.connect(audioContext.destination);
      source.start(0);
      console.log("Sound started successfully");
    } else {
      console.warn("Failed to load audio buffer for:", filename);
    }
  } catch (error) {
    console.error("Web Audio API failed, falling back to HTML5 Audio:", error);
    playSoundHTML5(filename);
  }
}

// Fallback to HTML5 Audio with iOS-specific handling
function playSoundHTML5(filename) {
  console.log("Using HTML5 Audio fallback for:", filename);
  const audio = new Audio(`/sounds/${filename}`);

  // iOS has volume restrictions
  audio.volume = 0.3; // Lower volume for iOS
  audio.preload = "auto"; // Preload the audio

  // iOS requires user interaction, so we need to handle this carefully
  const playPromise = audio.play();

  if (playPromise !== undefined) {
    playPromise
      .then(() => {
        console.log("HTML5 Audio played successfully");
      })
      .catch((error) => {
        console.error("HTML5 Audio failed:", error);
        // Try to resume audio context if it's suspended
        if (audioContext && audioContext.state === "suspended") {
          audioContext.resume();
        }
      });
  }
}

exports.init = async function (app) {
  // Initial load of data
  try {
    const [workouts, currentBurpee] = await Promise.all([
      loadWorkouts(),
      getCurrentBurpeeVariant(),
    ]);

    // Ensure workouts is an array and currentBurpee is properly formatted
    const safeWorkouts = Array.isArray(workouts) ? workouts : [];

    // Create the message object
    const message = {
      tag: "InitData",
      data: {
        workoutHistory: safeWorkouts,
        currentBurpeeVariant: currentBurpee,
        version: version,
      },
    };

    console.log("Sending to Elm:", message);

    // Convert to string before sending through port
    app.ports[TO_ELM_PORT].send(JSON.stringify(message));
  } catch (error) {
    console.error("Error loading initial data:", error);
  }

  app.ports[TO_JS_PORT].subscribe(async function (event) {
    console.log("fromElm", JSON.stringify(event));

    if (event.tag === undefined || event.tag === null) {
      console.error("fromElm event is missing a tag", event);
      return;
    }

    switch (event.tag) {
      case "StoreBurpeeVariant":
        await storeBurpeeVariant(event.data);
        break;
      case "StoreWorkout":
        await storeWorkout(event.data);
        break;
      case "LogError":
        console.error("BurpeeBootcamp Error:", event.data);
        break;
      case "PlaySound":
        playSound(event.data);
        break;
      default:
        console.log(`fromElm event of tag ${event.tag} not handled`, event);
    }
  });

  setupServiceworker();
};

// Initialize IndexedDB
function initDB() {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open("BurpeeBootcamp", 2);

    request.onerror = () => reject(request.error);

    request.onupgradeneeded = (event) => {
      const db = event.target.result;

      // Create workouts store with timestamp index
      if (!db.objectStoreNames.contains("workouts")) {
        const workoutStore = db.createObjectStore("workouts", {
          keyPath: "timestamp",
        });
        workoutStore.createIndex("date", "timestamp");
      }

      // Create burpee store
      if (!db.objectStoreNames.contains("burpee")) {
        db.createObjectStore("burpee", {
          keyPath: "id",
        });
      }
    };

    request.onsuccess = () => resolve(request.result);
  });
}

// Store a workout
async function storeWorkout(workout) {
  console.log("Storing workout:", workout);
  const db = await initDB();
  return new Promise((resolve, reject) => {
    const transaction = db.transaction(["workouts"], "readwrite");
    const store = transaction.objectStore("workouts");

    const request = store.put(workout);

    request.onsuccess = () => resolve();
    request.onerror = () => reject(request.error);
  });
}

// Load all workouts
async function loadWorkouts() {
  const db = await initDB();
  return new Promise((resolve, reject) => {
    const transaction = db.transaction(["workouts"], "readonly");
    const store = transaction.objectStore("workouts");
    const index = store.index("date");

    const request = index.getAll();

    request.onsuccess = () => {
      resolve(request.result);
    };
    request.onerror = () => reject(request.error);
  });
}

async function getCurrentBurpeeVariant() {
  const db = await initDB();
  return new Promise((resolve, reject) => {
    const transaction = db.transaction(["burpee"], "readonly");
    const store = transaction.objectStore("burpee");
    const request = store.get("current");

    request.onsuccess = () => resolve(request.result?.value || null);
    request.onerror = () => reject(request.error);
  });
}

async function storeBurpeeVariant(burpee) {
  const db = await initDB();
  return new Promise((resolve, reject) => {
    const transaction = db.transaction(["burpee"], "readwrite");
    const store = transaction.objectStore("burpee");
    const request = store.put({
      id: "current",
      value: burpee,
    });

    request.onsuccess = () => resolve();
    request.onerror = () => reject(request.error);
  });
}

function setupServiceworker() {
  if ("serviceWorker" in navigator) {
    window.addEventListener("load", async () => {
      try {
        const registration = await navigator.serviceWorker.register(
          "/serviceWorker.js"
        );
        console.log("ServiceWorker registration successful");
      } catch (err) {
        console.log("ServiceWorker registration failed: ", err);
      }
    });
  }
}
