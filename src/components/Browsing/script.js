import { mapGetters, mapActions } from "vuex";

import {
  IonContent,
  IonHeader,
  IonMenuButton,
  IonPage,
  IonTitle,
  IonToolbar,
  IonList
} from "@ionic/vue";
export default {
  name: "Browsing",
  components: {
    IonList,
    IonContent,
    IonHeader,
    IonMenuButton,
    IonPage,
    IonTitle,
    IonToolbar
  },
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
