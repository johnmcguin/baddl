// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";
import "./wordle.js";
let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: {
    ShowPlayerCount: {
      mounted() {
        const ls = localStorage.getItem("should_show_baddl_count");
        const shouldShow = ls === "true";
        if (!shouldShow) {
          this.el.style.display = "none";
        }
      },
    },
    AnimatePlayer: {
      mounted() {
        this.handleEvent("animate-player", function ({ player }) {
          const playerGuesses = document.querySelectorAll(
            `[id^=${player}-guess]`,
          );

          if (playerGuesses?.length) {
            for (let guess of playerGuesses) {
              guess.classList.add("reveal");
            }

            setTimeout(() => {
              for (let guess of playerGuesses) {
                guess.classList.remove("reveal");
              }
            }, 500);
          }
        });
      },
    },
    Wordle: {
      mounted() {
        if (window?.ELM_APP) {
          const appContainer = document.createElement("div");
          const { answer, game, room } = this.el.dataset;
          const history = JSON.parse(localStorage.getItem(room));
          const roomHistory = history ? history[game] : { [game]: [] };
          const flags = {
            word: answer,
            history: roomHistory,
          };
          this.el.appendChild(appContainer);

          const app = window.ELM_APP.Main.init({
            node: appContainer,
            flags,
          });

          app.ports.submitGuess.subscribe((guess) => {
            this.pushEventTo(this.el, "handle_guess", guess);
          });

          app.ports.submitWin.subscribe(() => {
            // hacky, but accomodates elm transition before sending
            setTimeout(() => {
              this.pushEventTo(this.el, "handle_win", {
                completedAt: Date.now(),
              });
            }, 1500);
          });

          app.ports.persistGuess.subscribe((guess) => {
            const gameState = JSON.parse(localStorage.getItem(room));
            const roomHistory = gameState ? gameState[game] : { [game]: [] };
            if (roomHistory?.length) {
              localStorage.setItem(
                room,
                JSON.stringify({ [game]: [...roomHistory, guess] }),
              );
            } else {
              localStorage.setItem(room, JSON.stringify({ [game]: [guess] }));
            }
          });
        }
      },
    },
  },
});
// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());
window.addEventListener("phx:set_game_id", (e) => console.log(e));

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
