import { Comms } from "../comms";

const comms = new Comms();
comms.init();

export default {
  state: {
    aspiration: "browsing",
    playName: "Macbeth",
    invitor: "Tessa",
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
    plays: [{ title: "Macbeth" }],
    comms
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
      state.invitationLink = state.comms.makeInvite();
    }
  }
};
