import { mapActions, mapGetters } from "vuex";

import * as vue from "@ionic/vue";
export default {
  name: "Naming",
  components: vue,
  data: () => ({ name: "" }),
  computed: { ...mapGetters({}) },
  methods: {
    ...mapActions({
      setName: "APP_SET_NAME"
    }),
    joinWithName() {
      this.setName(this.name);
    }
  }
};
