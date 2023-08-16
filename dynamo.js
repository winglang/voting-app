const { DynamoDBClient, GetItemCommand, PutItemCommand, ScanCommand } = require("@aws-sdk/client-dynamodb");

const client = new DynamoDBClient({});

// https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/client/dynamodb/command/PutItemCommand/
export async function _putItem(tableName, item) {
  const command = new PutItemCommand({
    TableName: tableName,
    Item: item,
  });
  console.log(command);
  
  const response = await client.send(command);
  console.log(response);
  return response;
}

// https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/client/dynamodb/command/GetItemCommand/
export async function _getItem(tableName, key) {
  const command = new GetItemCommand({
    TableName: tableName,
    Key: key,
  });
  console.log(command);
  
  const response = await client.send(command);
  console.log(response);
  if (!response.Item) {
    return undefined;
  }
  return response;
}

// https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/client/dynamodb/command/ScanCommand/
export async function _scan(tableName) {
  const command = new ScanCommand({
    TableName: tableName,
  });
  console.log(command);

  const response = await client.send(command);
  console.log(response);
  return response;
}
