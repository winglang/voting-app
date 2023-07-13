bring "@cdktf/provider-aws" as tfaws;
bring aws;
bring cloud;
bring util;

// --- dynamodb ---

enum AttributeType {
  String,
  Number, // note: DynamoDB requires you to provide the `value` as a string
  Binary,
}

struct Attribute {
  type: AttributeType;
  value: Json;
}

// TODO: https://github.com/winglang/wing/issues/3350
// typealias Item = Map<Attribute>;

// TODO: https://github.com/winglang/wing/issues/2939
let _equalAttributes = inflight (a: Attribute, b: Attribute): bool => {
  return a.type == b.type && a.value == b.value;
};

struct DynamoDBTableProps {
  hashKey: str;
}

class DynamoDBTable {
  table: tfaws.dynamodbTable.DynamodbTable;
  tableName: str;
  hashKey: str;
  init(props: DynamoDBTableProps) {
    let target = util.env("WING_TARGET");
    if target != "tf-aws" {
      throw("Unsupported target: ${target} (expected 'tf-aws')");
    }

    this.hashKey = props.hashKey;
    this.table = new tfaws.dynamodbTable.DynamodbTable(
      name: "Table-${this.node.addr.substring(this.node.addr.length - 8)}",
      billingMode: "PAY_PER_REQUEST",
      hashKey: this.hashKey,
      attribute: [
        {
          name: this.hashKey,
          type: "S",
        },
      ],
    );
    this.tableName = this.table.name;
  }

  _bind(host: std.IInflightHost, ops: Array<str>) {
    if let host = aws.Function.from(host) {
      if ops.contains("putItem") {
        host.addPolicyStatements([aws.PolicyStatement {
          actions: ["dynamodb:PutItem"],
          resources: [this.table.arn],
          effect: aws.Effect.ALLOW,
        }]);
      }

      if ops.contains("getItem") {
        host.addPolicyStatements([aws.PolicyStatement {
          actions: ["dynamodb:GetItem"],
          resources: [this.table.arn],
          effect: aws.Effect.ALLOW,
        }]);
      }

      if ops.contains("scan") {
        host.addPolicyStatements([aws.PolicyStatement {
          actions: ["dynamodb:Scan"],
          resources: [this.table.arn],
          effect: aws.Effect.ALLOW,
        }]);
      }
    }
  }

  extern "./dynamo.js" inflight _putItem(tableName: str, item: Json): void;
  extern "./dynamo.js" inflight _getItem(tableName: str, key: Json): Map<Map<Map<str>>>;
  extern "./dynamo.js" inflight _scan(tableName: str): Map<Array<Map<Map<str>>>>;

  inflight putItem(item: Map<Attribute>) {
    let json = this._itemToJson(item);
    this._putItem(this.tableName, json);
  }

  inflight getItem(key: Map<Attribute>): Map<Attribute> {
    let json = this._itemToJson(key);
    let result = this._getItem(this.tableName, json);
    return this._rawMapToItem(result.get("Item"));
  }

  inflight scan(): Array<Map<Attribute>> {
    let result = this._scan(this.tableName);
    let rawItems = result.get("Items");
    let items = MutArray<Map<Attribute>>[];
    for rawItem in rawItems {
      let item = this._rawMapToItem(rawItem);
      items.push(item);
    }
    return items.copy();
  }

  inflight _itemToJson(item: Map<Attribute>): Json {
    let json = MutJson {};
    for key in item.keys() {
      let attribute = item.get(key);
      let attributeTypeStr = this._attributeTypeToString(attribute.type);

      let innerJson = MutJson {};
      innerJson.set(attributeTypeStr, attribute.value);
      json.set(key, innerJson);
    }
    return json;
  }

  inflight _rawMapToItem(input: Map<Map<str>>): Map<Attribute> {
    let item = MutMap<Attribute> {};
    for key in input.keys() {
      let attributeJson = input.get(key);
      let attributeTypeStr = attributeJson.keys().at(0);
      let attributeType = this._stringToAttributeType(attributeTypeStr);
      let attributeValue = attributeJson.get(attributeTypeStr);
      item.set(key, Attribute {
        type: attributeType,
        value: attributeValue,
      });
    }
    return item.copy();
  }

  inflight _attributeTypeToString(type: AttributeType): str {
    if type == AttributeType.String {
      return "S";
    } elif type == AttributeType.Number {
      return "N";
    } elif type == AttributeType.Binary {
      return "B";
    }
  }

  inflight _stringToAttributeType(type: str): AttributeType {
    if type == "S" {
      return AttributeType.String;
    } elif type == "N" {
      return AttributeType.Number;
    } elif type == "B" {
      return AttributeType.Binary;
    }
  }
}

// --- utils ---

// Check if an array of items contains an item with the given attributes
let containsItem = inflight (items: Array<Map<Attribute>>, attributes: Map<Attribute>): bool => {
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

let findItem = inflight (items: Array<Map<Attribute>>, attributes: Map<Attribute>): Map<Attribute>? => {
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

// struct Entry {
//   name: str;
//   score: str;
// }

let table = new DynamoDBTable(hashKey: "Name");

let api = new cloud.Api();

// returns a response in the format
// [
//   { "Name": "Fruit", "Score": "1" },
//   { "Name": "Vegetable", "Score": "0" },
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
    let updatedItem = MutMap<Attribute>{};
    updatedItem.set("Name", Attribute {
      type: AttributeType.String,
      value: userChoice,
    });
    updatedItem.set("Score", Attribute {
      type: AttributeType.Number,
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

test "put and get an item in the table" {
  table.putItem({
    "Name" => Attribute {
      type: AttributeType.String,
      value: "Fruit",
    },
    "Score" => Attribute {
      type: AttributeType.Number,
      value: "1500",
    },
  });

  let item = table.getItem({
    "Name" => Attribute {
      type: AttributeType.String,
      value: "Fruit",
    },
  });

  assert(item.get("Score").value == "1500");
}

test "scan items in the table" {
  table.putItem({
    "Name" => Attribute {
      type: AttributeType.String,
      value: "Fruit",
    },
    "Score" => Attribute {
      type: AttributeType.Number,
      value: "1500",
    },
  });
  table.putItem({
    "Name" => Attribute {
      type: AttributeType.String,
      value: "Vegetables",
    },
    "Score" => Attribute {
      type: AttributeType.Number,
      value: "1400",
    },
  });

  let items = table.scan();
  assert(items.length == 2);
  assert(containsItem(items, {
    "Name" => Attribute {
      type: AttributeType.String,
      value: "Fruit",
    },
    "Score" => Attribute {
      type: AttributeType.Number,
      value: "1500",
    },
  }));
  assert(containsItem(items, {
    "Name" => Attribute {
      type: AttributeType.String,
      value: "Vegetables",
    },
    "Score" => Attribute {
      type: AttributeType.Number,
      value: "1400",
    },
  }));
}
