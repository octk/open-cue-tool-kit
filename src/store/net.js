import P2p from "../core/p2p";
import Canon from "../core/canon";

export default {
  state: {
    client: null,
    canon: new Canon()
  },

  getters: {},

  mutations: {},

  actions: {
    // Initialization
    async NET_INIT({ dispatch }) {
      await dispatch("NET_INIT_CLIENT");
      await dispatch("NET_LOAD_SCRIPTS");
    },
    async NET_LOAD_SCRIPTS({ state, commit }) {
      commit("DIR_SET_PLAYS", await state.canon.loadScriptIndex());
    },
    async NET_ADD_LOCAL_SCRIPT({ state }, script) {
      await state.canon.addLocalScript(script);
    },
    async NET_INIT_CLIENT({ state, dispatch, commit, getters }) {
      state.client = new P2p();

      // Set p2p listeners for picking show
      state.client.onShareProduction = ({ id, title, lines }) => {
        commit("APP_ADD_PRODUCTION", { id, title, lines: JSON.parse(lines) });
      };
      state.client.onNewActor = () => {
        // Delay while new actor sets listeners
        setTimeout(() => {
          dispatch("DIR_INVITE_OPPORUNITY");
        }, 5000);
      };
      state.client.onAcceptInvite = identity => {
        if (getters.APP_ASPIRATION === "casting") {
          commit("DIR_ADD_ACTOR", identity);
        }
      };

      // Set p2p listeners for running show
      state.client.onBeginShow = ({ actorsByPart }) => {
        commit("APP_SET_ACTORS_BY_PART", actorsByPart);
        dispatch("APP_START_PLAY");
      };
      state.client.onCueNextActor = () => {
        if (getters.APP_ASPIRATION === "cueing") {
          dispatch("APP_NEXT_CUE");
        }
      };

      await state.client.init();
    },

    // Actions while picking show
    async NET_MAKE_INVITE({ state }, { title, lines }) {
      return await state.client.makeInvite(title, lines);
    },
    async NET_ACCEPT_INVITE({ state }, invite) {
      return await state.client.acceptInvite(invite);
    },
    async NET_SHARE_PRODUCTION({ state }, castingProduction) {
      return await state.client.shareProduction(castingProduction);
    },
    async NET_FETCH_SCRIPT({ state }, title) {
      return await state.canon.fetchScriptByTitle(title);
    },

    // Actions while running show
    async NET_BEGIN_SHOW({ state }, cast) {
      return await state.client.beginShow(cast);
    },
    async NET_CUE_NEXT_ACTOR({ state, dispatch }) {
      dispatch("APP_NEXT_CUE");
      return await state.client.cueNextActor();
    }
  }
};
