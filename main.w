bring cloud;
bring dynamodb;
bring fs;
bring math;
bring util;

// --- types ---

struct Entry {
  name: str;
  score: num;
}

struct SelectWinnerRequest {
  winner: str;
  loser: str;
}

struct SelectWinnerResponse {
  winner: num;
  loser: num;
}

class Util {
  pub static inflight clamp(value: num, min: num, max: num): num {
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
  table: dynamodb.Table;
  new() {
    this.table = new dynamodb.Table(
      attributes: [
        { name: "Name", type: "S" },
        // { name: "Score", type: "N" },
      ],
      hashKey: "Name",
    ) as "EntiresTable";
  }

  pub inflight setEntry(entry: Entry) {
    this.table.put({
      Item: {
        "Name": entry.name,
        "Score": entry.score,
      }
    });
  }

  pub inflight getEntry(name: str): Entry? {
    let result = this.table.get({
      Key: { "Name": name },
    });
    if let item = result.Item {
      return Entry {
        name: name,
        score: num.fromStr(item.get("Score").get("value").asStr()),
      };
    } else {
      return nil;
    }
  }

  pub inflight getRandomPair(): Array<Entry> {
    let scanned = this.table.scan();

    let firstIdx = math.floor(math.random() * scanned.Count);
    let var secondIdx = math.floor(math.random() * scanned.Count);

    // Make sure the two items are different
    while secondIdx == firstIdx {
      secondIdx = math.floor(math.random() * scanned.Count);
    }

    let first = Entry {
      name: scanned.Items.at(firstIdx).get("Name").asStr(),
      score: num.fromStr(scanned.Items.at(firstIdx).get("Score").get("value").asStr()),
    };
    let second = Entry {
      name: scanned.Items.at(secondIdx).get("Name").asStr(),
      score: num.fromStr(scanned.Items.at(secondIdx).get("Score").get("value").asStr()),
    };
    return [first, second];
  }

  pub inflight updateScores(winner: str, loser: str): Array<num> {
    let entries = this.list();

    let winnerEntry = this.getEntry(winner);
    let loserEntry = this.getEntry(loser);
    let var winnerScore = 0;
    let var loserScore = 0;
    if let winnerEntry = winnerEntry {
      winnerScore = winnerEntry.score;
    } else {
      throw("Winner is not a valid item");
    }
    if let loserEntry = loserEntry {
      loserScore = loserEntry.score;
    } else {
      throw("Loser is not a valid item");
    }

    // probability that the winner should have won
    let pWinner = 1.0 / (1.0 + 10 ** ((loserScore - winnerScore) / 400.0));

    let winnerNewScore = Util.clamp(winnerScore + 32 * (1.0 - pWinner), 0, 2000);
    let loserNewScore = Util.clamp(loserScore + 32 * (pWinner - 1.0), 0, 2000);

    this.setEntry(Entry { name: winner, score: winnerNewScore });
    this.setEntry(Entry { name: loser, score: loserNewScore });

    return [winnerNewScore, loserNewScore];
  }

  pub inflight list(): Array<Entry> {
    let scanned = this.table.scan();
    let entries = MutArray<Entry>[];
    for item in scanned.Items {
      entries.push(Entry {
        name: item.get("Name").asStr(),
        score: num.fromStr(item.get("Score").get("value").asStr()),
      });
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
    if !store.getEntry(food)? {
      store.setEntry(Entry {
        name: food,
        score: 1000 + math.floor(math.random() * 100) - 50, // 1000 +/- 50
      });
    }
  }
}) as "InitializeTable";

let api = new cloud.Api(cors: true) as "VotingAppApi";

let website = new cloud.Website(path: "./website/build");
website.addJson("config.json", { apiUrl: api.url });

// A hack to expose the api url to the React app for local development
if util.env("WING_TARGET") == "sim" {
  new cloud.OnDeploy(inflight () => {
    fs.writeFile("node_modules/.votingappenv", api.url);
  }) as "ReactAppSetup";
}

// Select two random items from the list of items for the user to choose between
api.post("/requestChoices", inflight (_) => {
  let entries = store.getRandomPair();
  let entryNames = MutArray<str>[];
  for entry in entries {
    entryNames.push(entry.name);
  }
  return cloud.ApiResponse {
    status: 200,
    body: Json.stringify(entryNames),
  };
});

// Obtain a list of all entries and their scores
api.get("/leaderboard", inflight (_) => {
  let entries = store.list();
  return cloud.ApiResponse {
    status: 200,
    body: Json.stringify(entries),
  };
});

// Select the winner between a pair of options
api.post("/selectWinner", inflight (req) => {
  let body = Json.parse(req.body ?? "");
  log(Json.stringify(body, indent: 2));
  let selections = SelectWinnerRequest.fromJson(body);

  let var newScores = Array<num>[];
  try {
     newScores = store.updateScores(selections.winner, selections.loser);
  } catch e {
    log(e);
    return cloud.ApiResponse {
      status: 400,
      body: "Error: " + Json.stringify(e),
    };
  }
  let payload = SelectWinnerResponse {
    winner: newScores.at(0),
    loser: newScores.at(1),
  };

  return cloud.ApiResponse {
    status: 200,
    body: Json.stringify(payload),
  };
});
