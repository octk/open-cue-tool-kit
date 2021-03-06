import * as components from "@ionic/vue";
import { mapGetters, mapActions } from "vuex";

export default {
  name: "Modal",
  components,
  data: () => ({
    options: ["Hamlet", "Ophelia", "Arthur"]
  }),
  computed: {
    ...mapGetters({})
  },
  methods: {
    ...mapActions({}),
    select() {
      console.log("select not yet implemented");
    }
  }
};
