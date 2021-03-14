import _ from "lodash";

import { mapGetters, mapActions } from "vuex";
import * as vue from "@ionic/vue";

import Modal from "../ModalCasting";
import QRCode from "qrcode";

export default {
  name: "Casting",
  components: { ...vue, Modal },
  computed: {
    ...mapGetters({
      playName: "PLAY_NAME",
      invitationLink: "INVITATION_LINK",
      partsByActor: "PARTS_BY_ACTOR",
      uncast: "UNCAST",
      autoCast: "AUTO_CAST"
    }),
    cast() {
      return _.map(this.partsByActor, (parts, actor) => ({
        name: actor,
        roles: parts
      }));
    }
  },
  mounted() {
    const canvas = document.getElementById("qrCanvas");
    QRCode.toCanvas(canvas, this.invitationLink, function(error) {
      if (error) console.error(error);
    });
  },
  methods: {
    ...mapActions({
      beginShow: "BEGIN_SHOW",
      toggleAutoCast: "TOGGLE_AUTO_CAST",
      setCasting: "SET_CASTING"
    }),
    copyInvitationLink() {
      navigator.clipboard.writeText(this.invitationLink);
    },
    async castingModal(casting) {
      this.setCasting(casting);
      const modal = await vue.modalController.create({
        component: Modal
      });
      return modal.present();
    }
  }
};
