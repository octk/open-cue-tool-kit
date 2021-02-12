import { mapGetters, mapActions } from "vuex";
import {
  IonButtons,
  IonContent,
  IonHeader,
  IonMenuButton,
  IonPage,
  IonTitle,
  IonToolbar
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
    IonToolbar
  },
  computed: {
    ...mapGetters({ productions: "PRODUCTIONS" })
  },
  methods: {
    ...mapActions({
      makeProduction: "MAKE_NEW_PRODUCTION",
      initComms: "INIT_COMMS",
      joinProduction: "ACCEPT_INVITE"
    })
  },
  created() {
    this.initComms();
  }
};
