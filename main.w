bring "./dynamodb.w" as ddb;
bring cloud;

// TODO: add image for each item?

// --- utils ---

// TODO: https://github.com/winglang/wing/issues/2939
let _equalAttributes = inflight (a: ddb.Attribute, b: ddb.Attribute): bool => {
  return a.type == b.type && a.value == b.value;
};

// Check if an array of items contains an item with the given attributes
let containsItem = inflight (items: Array<Map<ddb.Attribute>>, attributes: Map<ddb.Attribute>): bool => {
  for i in items {
    let var matches = true;
    for key in attributes.keys() {
      if !_equalAttributes(i.get(key), attributes.get(key)) {
        matches = false;
        break;
      }
    }
    if matches {
      return true;
    }
  }
  return false;
};

let findItem = inflight (items: Array<Map<ddb.Attribute>>, attributes: Map<ddb.Attribute>): Map<ddb.Attribute>? => {
  for i in items {
    let var matches = true;
    for key in attributes.keys() {
      if !_equalAttributes(i.get(key), attributes.get(key)) {
        matches = false;
        break;
      }
    }
    if matches {
      return i;
    }
  }
  return nil;
};
let findItem2 = inflight (items: Array<Map<str>>, item: Map<str>): Map<str>? => {
  for i in items {
    let var matches = true;
    for key in item.keys() {
      if i.get(key) != item.get(key) {
        matches = false;
        break;
      }
    }
    if matches {
      return i;
    }
  }
  return nil;
};

class Util {
  extern "./util.js" static inflight jsonToArray(json: Json): Array<Map<str>>;
  extern "./util.js" static inflight mutArrayMapToJson(items: MutArray<Map<str>>): Json;
}

// --- application ---

// TODO https://github.com/winglang/wing/issues/3139

struct Entry {
  name: str;
  score: str;
}

let table = new ddb.DynamoDBTable(hashKey: "Name") as "VotingAppItems";

let items = [
  "Consciousness",
  "Nature",
  "Happiness",
  "Water",
  "Love",
  "Oxygen",
  "Earth",
  "Friendship",
  "Brain",
  "Time",
  "Health",
  "Wisdom",
  "Sleep",
  "Laughter",
  "Curiosity",
  "Sunlight",
  "Learning",
  "Technology",
  "Sun",
  "DNA",
  "Electricity",
  "Internet",
  "Art",
  "Numbers",
  "Hydrogen",
  "Big Bang",
  "Biology",
  "Cooking",
  "Big dogs",
  "Men",
  "Women",
  "Music",
  "Family",
  "Colors",
  "Open source",
  "Wi-Fi",
  "Forgiveness",
  "Rain",
  "Hugs",
  "Education",
  "Carbon",
  "Ocean",
  "Algebra",
  "Plant",
  "Bread",
  "Independence",
  "Freedom of speech",
  "Jokes",
  "Computers",
  "Raccoons",
  "Cats",
  "Fruit",
  "Vegetables",
  "Sunset",
  "Wikipedia",
  "Vaccines",
  "History",
  "Agriculture",
  "Walking",
  "Health care",
  "Conversation",
  "Moon",
  "Air conditioning",
  "Proton",
  "Albert Einstein",
  "Kitten",
  "Probability",
  "Libraries",
  "Autumn",
  "Democracy",
  "Sense of taste",
  "Swimming",
  "Wheels",
  "Trees",
  "Four-day workweek",
  "Sunrise",
  "Space",
  "Skin",
  "Face",
  "Philosophy",
  "Antibiotics",
  "Naps",
  "Women's rights",
  "Courage",
  "Ice cream",
  "Hearing",
  "Mathematics",
  "Laptop",
  "Vegetable",
  "Depth perception",
  "Eating",
  "Listening",
  "Justice",
  "Pizza",
  "Medicine",
  "Potato",
  "Shower",
  "Periodic table",
  "Antibody",
  "Metric system",
  "Imperial system",
  "Salt",
  "Pepper",
  "Breakfast",
  "Lunch",
  "Dinner"
];

new cloud.OnDeploy(inflight () => {
  for item in items {
    table.putItem({
      "Name" => ddb.Attribute {
        type: ddb.AttributeType.String,
        value: item,
      },
      "Score" => ddb.Attribute {
        type: ddb.AttributeType.Number,
        value: "0",
      },
    });
  }
}) as "InitializeTable";

let api = new cloud.Api();

// returns a response in the format
// [
//   { "Name": "Fruit", "Score": "1" },
//   { "Name": "Vegetable", "Score": "0" },
//   ...
// ]
api.get("/items", inflight (req: cloud.ApiRequest): cloud.ApiResponse => {
  let items = table.scan();
  let itemsFormatted = MutArray<Map<str>>[];
  for item in items {
    itemsFormatted.push({
      "Name" => str.fromJson(item.get("Name").value),
      "Score" => str.fromJson(item.get("Score").value),
    });
  }
  return cloud.ApiResponse {
    status: 200,
    body: Json.stringify(itemsFormatted),
  };
});

// expects a request in the format
// {
//   "options": [
//     { "Name": "Fruit", "Score": "0" },
//     { "Name": "Vegetable", "Score": "0" },
//    ],
//   "userChoice": "Fruit",
// }
// and returns a response in the format
// {
//   "updatedOptions": {
//     { "Name": "Fruit", "Score": "1" },
//     { "Name": "Vegetable", "Score": "0" },
//   },
// }
//
// example:
// curl -X POST -H "Content-Type: application/json" -d '{"options":[{"Name":"Fruit","Score":"0"},{"Name":"Vegetable","Score":"0"}],"userChoice":"Fruit"}' http://localhost:8080/vote
api.post("/vote", inflight (req: cloud.ApiRequest): cloud.ApiResponse => {
  let body = Json.parse(req.body ?? "");
  log(Json.stringify(body, 2));
  let userChoice = str.fromJson(body.get("userChoice"));
  // TODO: https://github.com/winglang/wing/issues/1796
  let options = Util.jsonToArray(body.get("options"));

  if options.length != 2 {
    return cloud.ApiResponse {
      status: 400,
      body: Json.stringify({
        "error": "Invalid number of options (expected 2)",
      }),
    };
  }

  let winningItem = findItem2(options, { "Name" => userChoice });

  if let winningItem = winningItem {
    // update the winning item, and format it as a DynamoDB Item
    let updatedItem = MutMap<ddb.Attribute>{};
    updatedItem.set("Name", ddb.Attribute {
      type: ddb.AttributeType.String,
      value: userChoice,
    });
    updatedItem.set("Score", ddb.Attribute {
      type: ddb.AttributeType.Number,
      value: "${num.fromStr(winningItem.get("Score")) + 1}",
    });
    table.putItem(updatedItem.copy());

    // update the options array
    let updatedOptions = MutArray<Map<str>>[];
    for option in options {
      if option.get("Name") == userChoice {
        updatedOptions.push({
          "Name" => userChoice,
          "Score" => "${num.fromStr(option.get("Score")) + 1}",
        });
      } else {
        updatedOptions.push(option);
      }
    }

    return cloud.ApiResponse {
      status: 200,
      body: Json.stringify({
        "updatedOptions": Util.mutArrayMapToJson(updatedOptions),
      }),
    };
  } else {
    return cloud.ApiResponse {
      status: 400,
      body: Json.stringify({
        "error": "User choice does not match options",
      }),
    };
  }
});

// --- tests ---
