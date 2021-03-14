import { mapGetters, mapActions } from "vuex";
import * as components from "@ionic/vue";

export default {
  name: "Starting",
  components,
  computed: {
    ...mapGetters({ productions: "APP_PRODUCTIONS" })
  },
  methods: {
    ...mapActions({
      init: "NET_INIT",
      makeProduction: "DIR_MAKE_NEW_PRODUCTION",
      joinProduction: "ACT_ACCEPT_INVITE"
    })
  },
  created() {
    this.init();
  }
};
