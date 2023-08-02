bring "./dynamodb.w" as ddb;
bring cloud;

// TODO: add image for each item?

// --- utils ---

// Check if an array of items contains an item with the given attributes
let containsItem = inflight (items: Array<Map<ddb.Attribute>>, attributes: Map<ddb.Attribute>): bool => {
  for i in items {
    let var matches = true;
    for key in attributes.keys() {
      if i.get(key) != attributes.get(key) {
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
      if i.get(key) != attributes.get(key) {
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

let api = new cloud.Api() as "VotingAppApi";

let website = new cloud.Website(
  path: "./website/build",
);
website.addJson("config.json", { apiUrl: api.url });

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
    // TODO: refactor to a constant - https://github.com/winglang/wing/issues/3119
    headers: {
      "Access-Control-Allow-Headers" => "*",
      "Access-Control-Allow-Origin" => "*",
      "Access-Control-Allow-Methods" =>  "OPTIONS,GET",
    },
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
      headers: {
      "Access-Control-Allow-Headers" => "*",
      "Access-Control-Allow-Origin" => "*",
      "Access-Control-Allow-Methods" =>  "OPTIONS,GET",
    },
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
      headers: {
      "Access-Control-Allow-Headers" => "*",
      "Access-Control-Allow-Origin" => "*",
      "Access-Control-Allow-Methods" =>  "OPTIONS,GET",
    },
      status: 200,
      body: Json.stringify({
        "updatedOptions": Util.mutArrayMapToJson(updatedOptions),
      }),
    };
  } else {
    return cloud.ApiResponse {
      headers: {
      "Access-Control-Allow-Headers" => "*",
      "Access-Control-Allow-Origin" => "*",
      "Access-Control-Allow-Methods" =>  "OPTIONS,GET",
    },
      status: 400,
      body: Json.stringify({
        "error": "User choice does not match options",
      }),
    };
  }
});

// --- tests ---
