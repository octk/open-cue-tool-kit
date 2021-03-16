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
    NET_INIT({ dispatch }) {
      dispatch("NET_LOAD_SCRIPTS");
      dispatch("NET_INIT_CLIENT");
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

      // Set p2p listeners for acting and directing
      state.client.onCueNextActor = () => {
        dispatch("APP_NEXT_CUE");
      };
      state.client.onShareProduction = production => {
        commit("APP_ADD_PRODUCTION", production);
      };
      state.client.onBeginShow = ({ actorsByPart }) => {
        commit("APP_SET_ACTORS_BY_PART", actorsByPart);
        dispatch("APP_START_PLAY");
      };
      state.client.onAcceptInvite = identity => {
        commit("DIR_ADD_ACTOR", identity);
      };
      state.client.onNewActor = () => {
        // Delay while new actor sets listeners
        setTimeout(() => {
          dispatch("DIR_INVITE_OPPORUNITY");
        }, 5000);
      };

      await state.client.init();
    },

    async NET_BEGIN_SHOW({ state }, cast) {
      return await state.client.beginShow(cast);
    },
    async NET_SHARE_PRODUCTION({ state }, castingProduction) {
      return await state.client.shareProduction(castingProduction);
    },
    async NET_FETCH_SCRIPT({ state }, title) {
      return await state.canon.fetchScriptByTitle(title);
    },
    async NET_MAKE_INVITE({ state }, title) {
      return await state.client.makeInvite(title);
    },
    async NET_CUE_NEXT_ACTOR({ state }) {
      return await state.client.cueNextActor();
    },
    async NET_ACCEPT_INVITE({ state }, invite) {
      return await state.client.acceptInvite(invite);
    }
  }
};
