import Vuex from "vuex";

import app from "./app";
import net from "./net";
import actor from "./actor";
import director from "./director";

function createStore() {
  return new Vuex.Store({
    modules: {
      net,
      app,
      actor,
      director
    }
  });
}

export default createStore;
