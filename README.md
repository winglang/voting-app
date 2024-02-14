# Battle of the Bites!

**_Get ready to indulge your taste buds and crown the ultimate culinary champion in Battle of the Bites!_** 🍔🍕🍣
Vote on different matchups as iconic dishes from around the world go head-to-head.

<center>
<b><a href="https://d1uu5g7pkrzn0o.cloudfront.net/">Live Demo</a></b>
</center>
<br>

[![Battle of the Bites screenshot](screenshot.png)](https://d1uu5g7pkrzn0o.cloudfront.net/)

Inspired by https://eloeverything.co/.

## Development

### Testing

You can test the web app locally using Wing Console.

1. Run `npm run build-react` to build the website.
2. Run `wing it main.w` to launch the Wing Console in your browser.
3. In the Wing Console, locate the website resource, and click on it to see its properties on the right sidebar. Click on the URL property to open visit the website in your browser.

For working on the React app, you can `cd` into the `website` directory and run `npm run start` to start the React app, which will automatically connect to the Wing simulator if you have the Wing Console running.
The page will automatically reload if you make changes to the React code.

### Deployment

To deploy your own copy of the app, first make sure you have AWS credentials configured in your terminal for the account and region you want to deploy to.
Then run the following commands to compile the app into Terraform, and deploy it:

```
wing compile -t tf-aws main.w
terraform -chdir=./target/main.tfaws init
terraform -chdir=./target/main.tfaws apply
```

## Contributions

Pull requests are welcome.

## License

This project is distributed under the [MIT](./LICENSE) license.
