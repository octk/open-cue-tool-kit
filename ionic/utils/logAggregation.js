//  _                  _   _            _
// | |    ___   __ _  | | | | __ _  ___| | __
// | |   / _ \ / _` | | |_| |/ _` |/ __| |/ /
// | |__| (_) | (_| | |  _  | (_| | (__|   <
// |_____\___/ \__, | |_| |_|\__,_|\___|_|\_\
//             |___/
//
// For debugging p2p clients, report gossipub logs to
// central server

let logCache = [];
console.debug = function() {
  logCache.push(arguments);
};

setInterval(() => {
  const serializedCache = JSON.stringify(logCache);
  logCache = [];
  const request = new Request("/.netlify/functions/log", {
    method: "POST",
    body: serializedCache
  });
  fetch(request);
}, 5000);

/* Libp2p2 debug config */
const debug = require("debug");
debug.log = console.debug.bind(console);
debug.enable("libp2p:gossipsub*");
