line = "mannequin, car1, boat, car2, stopsign, plane1, bus1, snowboard, umbrella, baseballbat, mattress, tennisracket, skis, suitcase, motorcycle, sportsball1, sportsball2, sportsball3, sportsball4, mattress2"
names: list[str] = line.lower().split(', ')
ln = [
    "".join(filter(lambda c: c.isalpha(), name))
    for name in names
] # remove number at end, then remove dup
ln = list(set(ln))

out = dict()
for i in range(len(ln)):
    out[str(i)] = ln[i]

import json
out = json.dumps(out)

print(out)

