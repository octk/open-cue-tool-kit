export default {
  state: {
    aspiration: "accepting",
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
    ]
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
    }
  },
  mutations: {
    SET_ASPIRATION(state, value) {
      state.aspiration = value;
    }
  }
};
