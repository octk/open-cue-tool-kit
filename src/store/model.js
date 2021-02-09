export default {
  state: {
    playName: "Macbeth",
    invitationLink: "cuecannon.com/asdf",
    cast: [
      { name: "Drew", role: "First Witch" },
      { name: "Shokai", role: "Second Witch" },
      { name: "Daniel", role: "Third Witch" }
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
    }
  }
};
