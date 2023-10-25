bring "@cdktf/provider-aws" as tfaws;
bring aws;
bring cloud;
bring util;

// --- dynamodb ---

pub enum AttributeType {
  String,
  Number, // note: DynamoDB requires you to provide the `value` as a string
  Binary,
}

pub struct Attribute {
  type: AttributeType;
  value: Json;
}

pub class Util {
  extern "./util.js" pub static inflight jsonToMutArray(json: Json): MutArray<Map<Attribute>>;
  extern "./util.js" pub static inflight jsonToArray(json: Json): Array<Map<Attribute>>;
  extern "./util.js" pub static inflight mutArrayToJson(json: MutArray<Map<Attribute>>): Json;
}

// TODO: https://github.com/winglang/wing/issues/3350
// typealias Item = Map<Attribute>;

struct DynamoDBTableProps {
  hashKey: str;
}

pub class DynamoDBTableSim {
  key: str;
  data: cloud.Bucket;

  init(props: DynamoDBTableProps) {
    this.key = "data.json";
    this.data = new cloud.Bucket();
    this.data.addObject(this.key, "[]");
  }

  pub inflight putItem(item: Map<Attribute>) {
    let items = this.data.getJson(this.key);
    let itemsMut = Util.jsonToMutArray(items);
    itemsMut.push(item);
    this.data.putJson(this.key, Util.mutArrayToJson(itemsMut));
  }

  pub inflight getItem(map: Map<Attribute>): Map<Attribute>? {
    let items = this.data.getJson(this.key);
    let itemsMut = Util.jsonToMutArray(items);
    for item in itemsMut {
      let var matches = true;
      for key in map.keys() {
        let attr1 = item.get(key);
        let attr2 = map.get(key);
        if attr1.value != attr2.value {
          matches = false;
          break;
        }
      }
      if matches {
        return item;
      }
    }
    return nil;
  }

  pub inflight scan(): Array<Map<Attribute>> {
    let items = this.data.getJson(this.key);
    return Util.jsonToArray(items);
  }
}

pub class DynamoDBTableAws {
  pub table: tfaws.dynamodbTable.DynamodbTable;
  tableName: str;
  hashKey: str;
  init(props: DynamoDBTableProps) {
    this.hashKey = props.hashKey;
    this.table = new tfaws.dynamodbTable.DynamodbTable(
      name: "${this.node.id}-${this.node.addr.substring(this.node.addr.length - 8)}",
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

  bind(host: std.IInflightHost, ops: Array<str>) {
    if let host = aws.Function.from(host) {
      if ops.contains("putItem") {
        host.addPolicyStatements(aws.PolicyStatement {
          actions: ["dynamodb:PutItem"],
          resources: [this.table.arn],
          effect: aws.Effect.ALLOW,
        });
      }

      if ops.contains("getItem") {
        host.addPolicyStatements(aws.PolicyStatement {
          actions: ["dynamodb:GetItem"],
          resources: [this.table.arn],
          effect: aws.Effect.ALLOW,
        });
      }

      if ops.contains("scan") {
        host.addPolicyStatements(aws.PolicyStatement {
          actions: ["dynamodb:Scan"],
          resources: [this.table.arn],
          effect: aws.Effect.ALLOW,
        });
      }
    }
  }

  extern "./dynamo.js" static inflight _putItem(tableName: str, item: Json): void;
  extern "./dynamo.js" static inflight _getItem(tableName: str, key: Json): Map<Map<Map<str>>>;
  extern "./dynamo.js" static inflight _scan(tableName: str): Map<Array<Map<Map<str>>>>;

  pub inflight putItem(item: Map<Attribute>) {
    let json = this._itemToJson(item);
    DynamoDBTableAws._putItem(this.tableName, json);
  }

  pub inflight getItem(key: Map<Attribute>): Map<Attribute> {
    let json = this._itemToJson(key);
    let result = DynamoDBTableAws._getItem(this.tableName, json);
    return this._rawMapToItem(result.get("Item"));
  }

  pub inflight scan(): Array<Map<Attribute>> {
    let result = DynamoDBTableAws._scan(this.tableName);
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

pub class DynamoDBTable {
  tableSim: DynamoDBTableSim?;
  tableAws: DynamoDBTableAws?;

  init(props: DynamoDBTableProps) {
    let target = util.env("WING_TARGET");
    if target == "sim" {
      this.tableSim = new DynamoDBTableSim(props);
    } elif target == "tf-aws" {
      this.tableAws = new DynamoDBTableAws(props);
    } else {
      throw("DynamoDBTable doesn't support target '${target}'");
    }
  }

  bind(host: std.IInflightHost, ops: Array<str>) {
    // currently simulator does not require permissions
    // may change with https://github.com/winglang/wing/issues/3082
    if let tableAws = this.tableAws {
      if let host = aws.Function.from(host) {
        if ops.contains("putItem") {
          host.addPolicyStatements(aws.PolicyStatement {
            actions: ["dynamodb:PutItem"],
            resources: [tableAws.table.arn],
            effect: aws.Effect.ALLOW,
          });
        }

        if ops.contains("getItem") {
          host.addPolicyStatements(aws.PolicyStatement {
            actions: ["dynamodb:GetItem"],
            resources: [tableAws.table.arn],
            effect: aws.Effect.ALLOW,
          });
        }

        if ops.contains("scan") {
          host.addPolicyStatements(aws.PolicyStatement {
            actions: ["dynamodb:Scan"],
            resources: [tableAws.table.arn],
            effect: aws.Effect.ALLOW,
          });
        }
      }
    }
  }

  pub inflight getItem(key: Map<Attribute>): Map<Attribute>? {
    assert(key.size() == 1);
    if let tableSim = this.tableSim {
      return tableSim.getItem(key);
    }
    if let tableAws = this.tableAws {
      return tableAws.getItem(key);
    }
    throw("no table instance found for getItem");
  }

  pub inflight putItem(item: Map<Attribute>) {
    if let tableSim = this.tableSim {
      tableSim.putItem(item);
      return;
    }
    if let tableAws = this.tableAws {
      tableAws.putItem(item);
      return;
    }
    throw("no table instance found for putItem");
  }

  pub inflight scan(): Array<Map<Attribute>> {
    if let tableSim = this.tableSim {
      return tableSim.scan();
    }
    if let tableAws = this.tableAws {
      return tableAws.scan();
    }
    throw("no table instance found for scan");
  }
}
