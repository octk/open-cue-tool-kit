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
        dispatch("ACT_NEXT_CUE");
      };
      state.client.onShareProduction = production => {
        commit("ACT_ADD_PRODUCTION", production);
      };
      state.client.onBeginShow = ({ actorsByPart }) => {
        commit("ACT_SET_ACTORS_BY_PART", actorsByPart);
        dispatch("ACT_START_PLAY");
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

    NET_BEGIN_SHOW({ state }) {
      state.comms.beginShow(state.cast);
    },
    NET_SHARE_PRODUCTION({ state }, castingProduction) {
      state.comms.shareProduction(castingProduction);
    }
  }
};
