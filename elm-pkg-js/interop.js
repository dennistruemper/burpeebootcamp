/* elm-pkg-js
port supermario_copy_to_clipboard_to_js : String -> Cmd msg
*/

const version = "v16";
const TO_JS_PORT = "toJs";
const TO_ELM_PORT = "toElm";
const SERVICE_WORKER_PATH = "/serviceWorker.js";

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
    console.log("fromElm", event);

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
