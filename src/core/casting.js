import _ from "lodash";

export default function castPlay(lines, actors) {
  // See how many cues each part has
  const cueCountByPart = {};
  for (var i = 0; i < lines.length; i++) {
    const part = lines[i].s; // S for speaker
    if (!cueCountByPart[part]) {
      cueCountByPart[part] = 0; // Initialize
    }
    cueCountByPart[part] += 1;
  }

  const parts = Object.keys(cueCountByPart);
  const partsByActor = {};
  for (const actor of actors) {
    partsByActor[actor] = [];
  }
  // Split parts keeping cue count even(ish)
  for (i = 0; i < parts.length; i++) {
    const actorWithFewestCues = _.minBy(actors, actorName => {
      return _.sum(_.map(partsByActor[actorName], p => cueCountByPart[p]));
    });
    partsByActor[actorWithFewestCues].push(parts[i]);
  }

  const actorsByPart = {};
  for (i = 0; i < parts.length; i++) {
    const part = parts[i];
    for (const actor of actors) {
      if (_.includes(partsByActor[actor], part)) {
        actorsByPart[part] = actor;
      }
    }
  }

  return { actorsByPart, partsByActor };
}
