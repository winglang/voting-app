bring "./dynamodb.w" as ddb;
bring cloud;
bring math;

// TODO: add image for each item?

// --- types ---

struct Entry {
  name: str;
  score: num;
}

let _entryToMap = inflight (entry: Entry) => {
  return Map<ddb.Attribute> {
    "Name" => ddb.Attribute {
      type: ddb.AttributeType.String,
      value: entry.name,
    },
    "Score" => ddb.Attribute {
      type: ddb.AttributeType.Number,
      value: "${entry.score}",
    },
  };
};

let _mapToEntry = inflight (map: Map<ddb.Attribute>): Entry => {
  return Entry {
    name: str.fromJson(map.get("Name").value),
    score: num.fromStr(str.fromJson(map.get("Score").value)),
  };
};

struct SelectWinnerRequest {
  winner: str;
  loser: str;
}

struct SelectWinnerResponse {
  winner: num;
  loser: num;
}

class Util {
  extern "./util.js" static inflight jsonToSelectWinnerRequest(json: Json): SelectWinnerRequest;

  static inflight clamp(value: num, min: num, max: num): num {
    if value < min {
      return min;
    } elif value > max {
      return max;
    }
    return value;
  }
}

// --- application ---

class Store {
  table: ddb.DynamoDBTable;
  init() {
    this.table = new ddb.DynamoDBTable(hashKey: "Name") as "Entries";
  }

  inflight setEntry(entry: Entry) {
    this.table.putItem(_entryToMap(entry));
  }

  inflight getEntry(name: str): Entry {
    let item = this.table.getItem(Map<ddb.Attribute> {
      "Name" => ddb.Attribute {
        type: ddb.AttributeType.String,
        value: name,
      },
    });
    return Entry {
      name: name,
      score: num.fromStr(str.fromJson(item.get("Score").value)),
    };
  }

  inflight getRandomPair(): Array<Entry> {
    let entries = this.table.scan();

    let firstIdx = math.floor(math.random() * entries.length);
    let var secondIdx = math.floor(math.random() * entries.length);
    while secondIdx == firstIdx {
      secondIdx = math.floor(math.random() * entries.length);
    }

    let first = _mapToEntry(entries.at(firstIdx));
    let second = _mapToEntry(entries.at(secondIdx));
    return [first, second];
  }

  inflight updateScores(winner: str, loser: str): Array<num> {
    let entries = this.list();

    let winnerScore = this.getEntry(winner).score;
    let loserScore = this.getEntry(loser).score;

    // probability that the winner should have won
    let pWinner = 1.0 / (1.0 + 10 ** (loserScore - winnerScore) / 400.0);

    let winnerNewScore = Util.clamp(winnerScore + 32 * (1.0 - pWinner), 1000, 2000);
    let loserNewScore = Util.clamp(loserScore + 32 * (pWinner - 1.0), 1000, 2000);

    this.setEntry(Entry { name: winner, score: winnerNewScore });
    this.setEntry(Entry { name: loser, score: loserNewScore });

    return [winnerNewScore, loserNewScore];
  }

  inflight list(): Array<Entry> {
    let items = this.table.scan();
    let entries = MutArray<Entry>[];
    for item in items {
      entries.push(_mapToEntry(item));
    }
    return entries.copy();
  }
}

let store = new Store() as "VotingAppStore";

// about 40 items... any more and we need to start paginating
let foods = [
  "Nigiri sushi",
  "Pizza margherita",
  "Pulled pork",
  "Frozen yogurt",
  "Pad thai",
  "Nougat",
  "Milkshake",
  "Soy sauce",
  "Ravioli",
  "Gnocchi",
  "Crepes",
  "Spring rolls",
  "Mole",
  "Grilled cheese",
  "Pepperoni",
  "Churros",
  "Macarons",
  "Gouda",
  "Parmigiano Reggiano",
  "Fondue",
  "Tiramisu",
  "Fish and chips",
  "Churrasco",
  "Doughnut",
  "Chocolate chip cookie",
  "Bibimbap",
  "Bulgogi",
  "Naan",
  "Chutney",
  "Nori",
  "Ceviche",
  "Quesadilla",
  "Fajitas",
  "Baguette",
  "Guacamole",
  "Tonkatsu",
  "Penne",
  "Macaroni",
  "Hummus",
  "Mooncake",
  "Burrito",
];

new cloud.OnDeploy(inflight () => {
  for food in foods {
    store.setEntry(Entry {
      name: food,
      score: 1500,
    });
  }
}) as "InitializeTable";

let api = new cloud.Api() as "VotingAppApi";

let website = new cloud.Website(path: "./website/build");
website.addJson("config.json", { apiUrl: api.url });

// Select two random items from the list of items for the user to choose between
api.post("/requestChoices", inflight (_) => {
  let entries = store.getRandomPair();
  let entryNames = MutArray<str>[];
  for entry in entries {
    entryNames.push(entry.name);
  }
  return cloud.ApiResponse {
    // TODO: refactor to a constant - https://github.com/winglang/wing/issues/3119
    headers: {
      "Access-Control-Allow-Headers" => "*",
      "Access-Control-Allow-Origin" => "*",
      "Access-Control-Allow-Methods" =>  "OPTIONS,GET",
    },
    status: 200,
    body: Json.stringify(entryNames),
  };
});

// Obtain a list of all entries and their scores
api.get("/leaderboard", inflight (_) => {
  let entries = store.list();
  return cloud.ApiResponse {
    // TODO: refactor to a constant - https://github.com/winglang/wing/issues/3119
    headers: {
      "Access-Control-Allow-Headers" => "*",
      "Access-Control-Allow-Origin" => "*",
      "Access-Control-Allow-Methods" =>  "OPTIONS,GET",
    },
    status: 200,
    body: Json.stringify(entries),
  };
});

// Select the winner between a pair of options
api.post("/selectWinner", inflight (req) => {
  let body = Json.parse(req.body ?? "");
  log(Json.stringify(body, 2));
  // TODO: https://github.com/winglang/wing/pull/3648
  let selections = Util.jsonToSelectWinnerRequest(body);

  let newScores = store.updateScores(selections.winner, selections.loser);
  let payload = SelectWinnerResponse {
    winner: newScores.at(0),
    loser: newScores.at(1),
  };

  return cloud.ApiResponse {
    headers: {
    "Access-Control-Allow-Headers" => "*",
    "Access-Control-Allow-Origin" => "*",
    "Access-Control-Allow-Methods" =>  "OPTIONS,GET",
  },
    status: 200,
    body: Json.stringify(payload),
  };
});
