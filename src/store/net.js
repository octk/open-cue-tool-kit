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
      await dispatch("NET_LOAD_SCRIPTS");
      await dispatch("NET_INIT_CLIENT");
    },
    async NET_LOAD_SCRIPTS({ state, commit }) {
      const response = await state.canon.loadScriptIndex();
      commit(
        "DIR_SET_PLAYS",
        response.map(title => ({ title }))
      );
    },

    async NET_INIT_CLIENT({ state, dispatch, commit }) {
      state.client = new P2p();

      // Set p2p listeners for picking show
      state.client.onShareProduction = production => {
        commit("APP_ADD_PRODUCTION", production);
      };
      state.client.onNewActor = () => {
        // Delay while new actor sets listeners
        setTimeout(() => {
          dispatch("DIR_INVITE_OPPORUNITY");
        }, 5000);
      };
      state.client.onAcceptInvite = identity => {
        commit("DIR_ADD_ACTOR", identity);
      };

      // Set p2p listeners for running show
      state.client.onBeginShow = ({ actorsByPart }) => {
        commit("APP_SET_ACTORS_BY_PART", actorsByPart);
        dispatch("APP_START_PLAY");
      };
      state.client.onCueNextActor = () => {
        dispatch("APP_NEXT_CUE");
      };

      await state.client.init();
    },

    // Actions while picking show
    async NET_MAKE_INVITE({ state }, title) {
      return await state.client.makeInvite(title);
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
