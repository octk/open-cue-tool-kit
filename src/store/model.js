import Comms from "../net";
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
