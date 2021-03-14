import _ from "lodash";

export default {
  state: {
    aspiration: "starting",
    productionsById: {},
    actorsByPart: {}
  },
  getters: {
    APP_PARTS_BY_ACTOR(state) {
      if (!state.cast) return {};
      return state.cast.partsByActor;
    },
    APP_ACTORS_BY_PART(state) {
      if (!state.cast) return {};
      return state.cast.actorsByPart;
    },
    APP_ASPIRATION(state) {
      return state.aspiration;
    },
    APP_INVITOR(state) {
      return state.invitor;
    },
    APP_PRODUCTIONS(state) {
      return _.values(state.productionsById);
    }
  },
  mutations: {
    APP_SET_ASPIRATION(state, value) {
      state.aspiration = value;
    }
  },
  actions: {}
};
