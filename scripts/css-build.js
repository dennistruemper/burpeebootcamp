const { getCurrentVersion } = require("./get-version");
const { exec } = require("child_process");

const version = getCurrentVersion();

// Build CSS files with version number
const buildPublic = exec(
  `tailwindcss -i css/raw.css -o public/styles.v${version}.css ${
    process.argv.includes("--watch") ? "--watch" : ""
  }`,
  { stdio: "inherit" }
);

const buildLanding = exec(
  `tailwindcss -i css/raw.css -o landingpage/styles.v${version}.css ${
    process.argv.includes("--watch") ? "--watch" : ""
  }`,
  { stdio: "inherit" }
);

// Handle process output and errors
buildPublic.stdout?.pipe(process.stdout);
buildPublic.stderr?.pipe(process.stderr);
buildLanding.stdout?.pipe(process.stdout);
buildLanding.stderr?.pipe(process.stderr);
