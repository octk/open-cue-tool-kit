import { mapGetters, mapActions } from "vuex";
import * as components from "@ionic/vue";

export default {
  name: "Starting",
  components,
  computed: {
    ...mapGetters({ productions: "APP_PRODUCTIONS", invite: "APP_INVITATION" })
  },
  methods: {
    ...mapActions({
      init: "APP_INIT",
      makeProduction: "DIR_BROWSE_PLAYS",
      joinProduction: "APP_ACCEPT_INVITE"
    })
  },
  created() {
    this.init();
  }
};
