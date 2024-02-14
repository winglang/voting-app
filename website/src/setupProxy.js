const fs = require('fs');

module.exports = function(app) {
  app.use(
    '/config.json',
    function(req, res) {
        const apiUrl = fs.readFileSync("../node_modules/.votingappenv", "utf8");
        if (!apiUrl) {
            res.status(500).send("No API URL set. Are you running `wing it`?");
            return;
        }
        res.send({ apiUrl });
    }
  );
};
