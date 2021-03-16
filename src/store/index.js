import Vuex from "vuex";

import app from "./app";
import net from "./net";
import director from "./director";

function createStore() {
  return new Vuex.Store({
    modules: {
      net,
      app,
      director
    }
  });
}

export default createStore;
