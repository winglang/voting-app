An application that allows users to choose between different options and vote for their favorite one. Items that get more votes will get ranked higher.
The idea is to make something like https://eloeverything.co/.

## Development

To test the website, you must first deploy an instance of the application through `wing compile -t tf-aws main.w`, and then deploy the artifacts in `target/main.tfaws` using `terraform init` and `terraform apply`.

After, login to AWS to get the API Gateway URL, and add a `config.json` file to `website/public` that contains the following:

```json
{
    "apiUrl": "<API GATEWAY URL>",
}
```

Finally you can `cd` into `website` and run `npm run start` to start the development server.
