import * as components from "@ionic/vue";
import { mapGetters, mapActions } from "vuex";

export default {
  name: "Browsing",
  components,
  computed: {
    ...mapGetters({
      availablePlays: "PLAYS"
    })
  },
  methods: {
    ...mapActions({
      selectPlay: "SELECT_PLAY"
    })
  }
};
