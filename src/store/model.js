export default {
  state: {
    playName: "Macbeth"
  },
  getters: {
    PLAY_NAME(state) {
      return state.playName;
    }
  }
};
