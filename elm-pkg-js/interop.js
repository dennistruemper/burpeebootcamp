/* elm-pkg-js
port supermario_copy_to_clipboard_to_js : String -> Cmd msg
*/

const version = "v22";
const TO_JS_PORT = "toJs";
const TO_ELM_PORT = "toElm";
const SERVICE_WORKER_PATH = "/serviceWorker.js";

exports.init = async function (app) {
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

      default:
        console.log(`fromElm event of tag ${event.tag} not handled`, event);
    }
  });
  app.ports[TO_ELM_PORT].send(
    JSON.stringify({
      tag: "InitData",
      data: { currentBurpeeVariant: getCurrentBurpeeVariant() },
    })
  );
  setupServiceworker();
};

function setupServiceworker() {
  if ("serviceWorker" in navigator) {
    window.addEventListener("load", function () {
      navigator.serviceWorker
        .register(SERVICE_WORKER_PATH)
        .then((res) => {
          console.log("service worker registered");
        })
        .catch((err) => console.log("service worker not registered", err));
    });
  }
}

function getCurrentBurpeeVariant() {
  const serialized = localStorage.getItem("currentBurpeeVariant");
  return serialized ? JSON.parse(serialized) : null;
}

async function storeBurpeeVariant(burpee) {
  console.log("storeBurpeeVariant", burpee);
  const serialized = JSON.stringify(burpee);
  localStorage.setItem("currentBurpeeVariant", serialized);
}
