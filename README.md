Issue Beaver
============

**This is work in progress**

 * **Issue Beaver** scans your project's source code for comments containing *TODO*.

 * **Issue Beaver** automatically creates new issues on Github for each TODO comment it finds.

 * **Issue Beaver** automatically closes issues on Github when you remove a TODO comment.

The goal is to provide simple and lightweight tracking of low-level technical issues (TODOs) and make the project's progress more transparent for people who don't want to read the source code.

![a beaver](http://kidsfront.com/coloring-pages/sm_color/beaver.jpg)

Configuration
-------------

### Repository
Issue beaver tries to use the Github repository specified in **remote.origin** of your local git repository for storing the issues. If you want to use a different repository (e.g. that of your own fork) you can set the **issuebeaver.repository** config variable:

```
git config issuebeaver.repository eckardt/issue-beaver
```

### Github login
If you don't want to be asked for your Github login you can set the **github.user** config variable. Your Github password won't be stored.

```
git config github.user eckardt
```

### Issue labels
You can specify a list of labels that should be used for issues created by Issue Beaver. Make sure to create the labels for your repository using Github Issues' *Manage Labels* feature, otherwise Issue Beaver will fail.

```
git config issuebeaver.labels todo,@high
```