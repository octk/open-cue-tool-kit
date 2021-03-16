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
      playName: "DIR_PLAY_NAME",
      invitationLink: "DIR_INVITATION_LINK",
      partsByActor: "DIR_PARTS_BY_ACTOR",
      uncast: "DIR_UNCAST_ACTORS",
      autoCast: "DIR_AUTO_CAST",
      actors: "DIR_ACTORS"
    }),
    cast() {
      const namesByActorId = _.keyBy(this.actors, "identity");
      const actorName = id => _.get(namesByActorId, [id, "name"]) || id;
      return _.map(this.partsByActor, (parts, actorId) => ({
        name: actorName(actorId),
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
      beginShow: "DIR_BEGIN_SHOW",
      toggleAutoCast: "DIR_TOGGLE_AUTO_CAST",
      setCasting: "DIR_SET_CASTING"
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
