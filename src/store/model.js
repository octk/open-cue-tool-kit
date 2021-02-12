import Comms from "../net";
import _ from "lodash";
import midsummerAct3 from "../../midsummer3.json";

function castPlay(lines, actors) {
  // See how many cues each part has
  const cueCountByPart = {};
  for (var i = 0; i < lines.length; i++) {
    const part = lines[i].s; // S for speaker
    if (!cueCountByPart[part]) {
      cueCountByPart[part] = 0; // Initialize
    }
    cueCountByPart[part] += 1;
  }

  const parts = Object.keys(cueCountByPart);
  const partsByActor = {};
  for (const actor of actors) {
    partsByActor[actor] = [];
  }
  // Split parts keeping cue count even(ish)
  for (i = 0; i < parts.length; i++) {
    const actorWithFewestCues = _.minBy(actors, actorName => {
      return _.sum(_.map(partsByActor[actorName], p => cueCountByPart[p]));
    });
    partsByActor[actorWithFewestCues].push(parts[i]);
  }

  const actorsByPart = {};
  for (i = 0; i < parts.length; i++) {
    const part = parts[i];
    for (const actor of actors) {
      if (_.includes(partsByActor[actor], part)) {
        actorsByPart[part] = actor;
      }
    }
  }

  return { actorsByPart, partsByActor };
}

castPlay(midsummerAct3, ["Shokai", "Daniel", "Drew"]);

export default {
  state: {
    // These are for everyone
    comms: null,
    productions: [],
    plays: [{ title: "Macbeth" }],
    aspiration: "starting",

    // These are for someone running a production
    playName: "Macbeth",
    invitationLink: "cuecannon.com/asdf",
    cast: [
      { name: "Drew", roles: ["First Witch", "Macbeth"] },
      {
        name: "Shokai",
        roles: [
          "Second Witch",
          "Macbeth",
          "Lady M",
          "Boatswain",
          "Prospero",
          "Jackie Chan"
        ]
      },
      { name: "Daniel", roles: ["Third Witch", "Macbeth"] }
    ],

    // These are for someone joining a production
    cue: ""
  },
  getters: {
    PLAY_NAME(state) {
      return state.playName;
    },
    INVITATION_LINK(state) {
      return state.invitationLink;
    },
    CAST(state) {
      return state.cast;
    },
    ASPIRATION(state) {
      return state.aspiration;
    },
    INVITOR(state) {
      return state.invitor;
    },
    PLAYS(state) {
      return state.plays;
    },
    PRODUCTIONS(state) {
      return state.productions;
    },
    CUE(state) {
      return state.cue;
    }
  },
  mutations: {
    SET_ASPIRATION(state, value) {
      state.aspiration = value;
    }
  },
  actions: {
    SELECT_PLAY({ state }, play) {
      state.playName = play.title;
      state.aspiration = "casting";
      state.cast = [];

      const id = state.comms.makeInvite(play.title);
      state.productions.push({ id, title: play.title });
    },
    MAKE_NEW_PRODUCTION({ state }) {
      state.aspiration = "browsing";
    },

    INIT_COMMS({ state }) {
      state.comms = new Comms();
      state.comms.onNewProduction = function(production) {
        state.productions.push(production);
      };
      state.comms.onAcceptInvite = function({ identity }) {
        state.cast.push({ name: identity, roles: ["Macbeth"] });
      };
      state.comms.init();
    },

    ACCEPT_INVITE({ state }, production) {
      state.aspiration = "cueing";
      state.comms.acceptInvite(production);
    }
  }
};
