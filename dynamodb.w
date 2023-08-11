bring "@cdktf/provider-aws" as tfaws;
bring aws;
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
