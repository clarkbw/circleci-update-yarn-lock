# CircleCI update yarn.lock

Script to update your [yarn.lock](https://yarnpkg.com/en/docs/yarn-lock) file from CircleCI, run this after every [greenkeeper](https://greenkeeper.io/) PR.

## Usage

Use this script to update your `yarn.lock` file whenever greenkeeper reminds you to update.

### Install

You need to add this module to your `package.json`.

```
yarn add --dev circleci-update-yarn-lock
```

Then add this to your `package.json` scripts.  The following script setup will work for the configure step next.

```json
"scripts": {
  "update-yarn-lock-file": "update-yarn-lock-file"
},
```

### Configure

Add the following to your `circle.yml` file to watch for greenkeeper branches and run this script when it sees them.

```yml
deployment:
  greenkeeper:
    branch: /greenkeeper\/.*/
    commands:
      - yarn run update-yarn-lock-file
```

## Development

**Requirements**

* [yarn](https://yarnpkg.com/).

```bash
brew install yarn
```

**Clone Repository**

```bash
git clone --recurse-submodules git@github.com:clarkbw/circleci-update-yarn-lock.git
cd circleci-update-yarn-lock
```

## Tests

**Requirements**

* [bats](https://github.com/sstephenson/bats)

```bash
brew install bats
```

**Running Tests**

```bash
yarn test
```
