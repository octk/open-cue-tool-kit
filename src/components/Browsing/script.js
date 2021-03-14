import * as components from "@ionic/vue";
import { mapGetters, mapActions } from "vuex";

export default {
  name: "Browsing",
  components,
  computed: {
    ...mapGetters({
      availablePlays: "DIR_PLAYS"
    })
  },
  methods: {
    ...mapActions({
      selectPlay: "DIR_SELECT_PLAY"
    })
  }
};
