import _ from "lodash";

import { mapGetters, mapActions } from "vuex";
import * as ionic from "@ionic/vue";

import CastingModal from "../ModalCasting";
import QRCode from "qrcode";

export default {
  name: "Casting",
  components: { ...ionic, CastingModal },
  computed: {
    ...mapGetters({
      playName: "DIR_PLAY_NAME",
      invitationLink: "DIR_INVITATION_LINK",
      partsByActor: "DIR_PARTS_BY_ACTOR",
      uncastActors: "DIR_UNCAST_ACTORS",
      uncastRoles: "DIR_UNCAST_ROLES",
      autoCast: "DIR_AUTO_CAST",
      actors: "DIR_ACTORS"
    }),
    cast() {
      const namesByActorId = _.keyBy(this.actors, "identity");
      const actorName = id => _.get(namesByActorId, [id, "name"]) || id;
      return _.map(this.partsByActor, (parts, actorId) => ({
        id: actorId,
        name: actorName(actorId),
        roles: parts
      }));
    },
    uncastCount() {
      return this.uncastActors.length + this.uncastRoles.length;
    }
  },
  watch: {
    invitationLink() {
      this.mountQRCode();
    }
  },
  methods: {
    ...mapActions({
      beginShow: "DIR_BEGIN_SHOW",
      toggleAutoCast: "DIR_TOGGLE_AUTO_CAST",
      setCasting: "DIR_SET_CASTING",
      deployCastingModal: "DIR_DEPLOY_CASTING_MODAL"
    }),
    copyInvitationLink() {
      navigator.clipboard.writeText(this.invitationLink);
    },
    async castingModal(casting) {
      this.setCasting(casting);
      this.deployCastingModal({
        component: CastingModal
      });
    },
    mountQRCode() {
      if (this.invitationLink) {
        const canvas = document.getElementById("qrCanvas");
        QRCode.toCanvas(canvas, this.invitationLink, function(error) {
          if (error)
            console.error(
              `Failed to create QR code with invitation link ${this.invitationLink}: ${error}`
            );
        });
      }
    }
  }
};
