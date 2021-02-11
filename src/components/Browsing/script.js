import { mapGetters, mapActions } from "vuex";

import {
  IonContent,
  IonHeader,
  IonMenuButton,
  IonPage,
  IonTitle,
  IonToolbar,
  IonList,
  IonListItem
} from "@ionic/vue";
export default {
  name: "Browsing",
  components: {
    IonList,
    IonListItem,
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
