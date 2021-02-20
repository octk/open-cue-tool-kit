import { mapGetters, mapActions } from "vuex";
import {
  IonButtons,
  IonContent,
  IonHeader,
  IonMenuButton,
  IonPage,
  IonTitle,
  IonToolbar,
  IonIcon
} from "@ionic/vue";
export default {
  name: "Starting",
  components: {
    IonButtons,
    IonContent,
    IonHeader,
    IonMenuButton,
    IonPage,
    IonTitle,
    IonToolbar,
    IonIcon
  },
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
