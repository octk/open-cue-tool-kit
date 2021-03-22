import _ from "lodash";

export default function castPlay(lines, actors, manuallyCast, autoCast) {
  const actorIds = _.map(actors, "identity");
  // See how many cues each part has
  const cueCountByPart = {};
  for (var i = 0; i < lines.length; i++) {
    const part = lines[i].s; // S for speaker
    if (!cueCountByPart[part]) {
      cueCountByPart[part] = 0; // Initialize
    }
    cueCountByPart[part] += 1;
  }

  const partsByActor = {};
  const parts = Object.keys(cueCountByPart);
  for (const actor of actorIds) {
    partsByActor[actor] = [];
    _.forEach(manuallyCast, (a, part) => {
      if (a === actor) {
        partsByActor[actor].push(part);
      }
    });
  }

  if (autoCast) {
    // Split parts keeping cue count even(ish)
    _.forEach(parts, part => {
      if (!manuallyCast[part]) {
        const actorWithFewestCues = _.minBy(actorIds, actorName => {
          return _.sum(_.map(partsByActor[actorName], p => cueCountByPart[p]));
        });
        partsByActor[actorWithFewestCues].push(part);
      }
    });
  }

  const actorsByPart = {};
  for (i = 0; i < parts.length; i++) {
    const part = parts[i];
    actorsByPart[part] = null;
    for (const actor of actorIds) {
      if (_.includes(partsByActor[actor], part)) {
        actorsByPart[part] = actor;
      }
    }
  }

  return { actorsByPart, partsByActor };
}
