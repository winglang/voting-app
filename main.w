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
}

// --- application ---

class Store {
  table: ddb.DynamoDBTable;
  init() {
    this.table = new ddb.DynamoDBTable(hashKey: "Name") as "Items";
  }

  inflight setEntry(entry: Entry) {
    this.table.putItem(_entryToMap(entry));
  }

  inflight getRandomPair(): Array<Entry> {
    let items = this.table.scan();

    let firstIdx = math.floor(math.random() * items.length);
    let var secondIdx = math.floor(math.random() * items.length);
    while secondIdx == firstIdx {
      secondIdx = math.floor(math.random() * items.length);
    }

    let first = _mapToEntry(items.at(firstIdx));
    let second = _mapToEntry(items.at(secondIdx));
    return [first, second];
  }

  inflight updateScores(winner: str, loser: str): Array<num> {
    let entries = this.list();

    let var winnerScore = 0;
    let var loserScore = 0;
    for entry in entries {
      if entry.name == winner {
        winnerScore = entry.score;
      } elif entry.name == loser {
        loserScore = entry.score;
      }
    }

    let var winnerNewScore = winnerScore + 1;
    let var loserNewScore = loserScore - 1;
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
      score: 0,
    });
  }
}) as "InitializeTable";

let api = new cloud.Api() as "VotingAppApi";

let website = new cloud.Website(
  path: "./website/build",
);
website.addJson("config.json", { apiUrl: api.url });

// Select two random items from the list of items for the user to choose between
api.post("/requestChoices", inflight (_) => {
  let items = store.getRandomPair();
  let itemNames = MutArray<str>[];
  for item in items {
    itemNames.push(item.name);
  }
  return cloud.ApiResponse {
    // TODO: refactor to a constant - https://github.com/winglang/wing/issues/3119
    headers: {
      "Access-Control-Allow-Headers" => "*",
      "Access-Control-Allow-Origin" => "*",
      "Access-Control-Allow-Methods" =>  "OPTIONS,GET",
    },
    status: 200,
    body: Json.stringify(itemNames),
  };
});

// Obtain a list of all items and their scores
api.get("/items", inflight (_) => {
  let items = store.list();
  return cloud.ApiResponse {
    // TODO: refactor to a constant - https://github.com/winglang/wing/issues/3119
    headers: {
      "Access-Control-Allow-Headers" => "*",
      "Access-Control-Allow-Origin" => "*",
      "Access-Control-Allow-Methods" =>  "OPTIONS,GET",
    },
    status: 200,
    body: Json.stringify(items),
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
