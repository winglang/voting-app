const { DynamoDBClient, GetItemCommand, PutItemCommand, ScanCommand } = require("@aws-sdk/client-dynamodb");

const client = new DynamoDBClient({});

// https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/client/dynamodb/command/PutItemCommand/
export async function _putItem(tableName, item) {
  const putItemInput = {
    TableName: tableName,
    Item: item,
  };
  console.log(putItemInput);
  const command = new PutItemCommand(putItemInput);
  const response = await client.send(command);
  console.log(response);
  return response;
}

// https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/client/dynamodb/command/GetItemCommand/
export async function _getItem(tableName, key) {
  const getItemInput = {
    TableName: tableName,
    Key: key,
  };
  console.log(getItemInput);
  const command = new GetItemCommand(getItemInput);
  
  const response = await client.send(command);
  console.log(response);
  if (!response.Item) {
    return undefined;
  }
  return response;
}

// https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/client/dynamodb/command/ScanCommand/
export async function _scan(tableName) {
  const scanInput = {
    TableName: tableName,
  };
  console.log(scanInput);
  const command = new ScanCommand(scanInput);

  const response = await client.send(command);
  console.log(response);
  return response;
}
