var faker, fs;

fs = require('fs');

faker = require('faker');

module.exports = {
  generateUsers: function() {
    var comments, email, i, name, password, posts, username, users, _i;
    users = [];
    for (i = _i = 1; _i <= 1; i = ++_i) {
      name = faker.Name.findName();
      username = faker.Helpers.slugify(faker.Internet.userName()).toLowerCase();
      password = faker.Helpers.slugify(faker.Internet.userName());
      posts = (function() {
        var _j, _results;
        _results = [];
        for (i = _j = 1; _j <= 10; i = ++_j) {
          _results.push(faker.Lorem.paragraphs());
        }
        return _results;
      })();
      comments = (function() {
        var _j, _results;
        _results = [];
        for (i = _j = 1; _j <= 10; i = ++_j) {
          _results.push(faker.Lorem.paragraph());
        }
        return _results;
      })();
      while (username.length < 8) {
        username = faker.Helpers.slugify(faker.Internet.userName().toLowerCase());
      }
      while (password.length < 12) {
        password = faker.Helpers.slugify(faker.Internet.userName());
      }
      email = "kodingtestuser+" + username + "@gmail.com";
      users.push({
        name: name,
        email: email,
        username: username,
        password: password,
        posts: posts,
        comments: comments
      });
    }
    fs.writeFileSync('users.json', JSON.stringify(users), 'utf-8');
    return users;
  },
  getUser: function() {
    var users, usersFile;
    try {
      usersFile = fs.readFileSync('users.json');
      users = JSON.parse(usersFile);
      console.log("users.json found, returning first user");
      return users[0];
    } catch (_error) {
      console.log('users.json not exists, creating new users data');
      users = this.generateUsers();
      return users[0];
    }
  }
};