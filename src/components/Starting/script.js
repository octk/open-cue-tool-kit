import { mapGetters, mapActions } from "vuex";
import * as components from "@ionic/vue";

export default {
  name: "Starting",
  components,
  computed: {
    ...mapGetters({ productions: "PRODUCTIONS" })
  },
  methods: {
    ...mapActions({
      init: "INIT",
      makeProduction: "MAKE_NEW_PRODUCTION",
      joinProduction: "ACCEPT_INVITE"
    })
  },
  created() {
    this.init();
  }
};
