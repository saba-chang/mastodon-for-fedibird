Fedibird
========

[![GitHub release](https://img.shields.io/github/release/fedibird/mastodon.svg)][releases]
[![Build Status](https://img.shields.io/circleci/project/github/fedibird/mastodon.svg)][circleci]
[![Code Climate](https://img.shields.io/codeclimate/maintainability/fedibird/mastodon.svg)][code_climate]

[releases]: https://github.com/fedibird/mastodon/releases
[circleci]: https://circleci.com/gh/fedibird/mastodon
[code_climate]: https://codeclimate.com/github/fedibird/mastodon

Fedibird is a **free, open-source social network server** based on ActivityPub, which is a fork of Mastodon arranged with features maintained by Takeshi Umeda (noellabo). For the official version of Mastodon, please visit the [official website](https://joinmastodon.org) and the [upstream repository](https://github.com/mastodon/mastodon).

This document describes the differences from Mastodon. Please also refer to the upstream [README.md](https://github.com/mastodon/mastodon/blob/main/README.md).

## Mission

Fedibird's mission is to expand the possibilities of Mastodon and the Fediverse by providing features that the official Mastodon is unable to adopt for various reasons.

Some features are intentionally left out of the official Mastodon. Some features also bring a different user experience. Some features are simply in an experimental status.

Fedibird will follow the official Mastodon and provide feedback on the results obtained here.

## Highlighted features

### Subscription

Feeds information of interest to your timeline in a different way than following. Accounts, hashtags, keywords, domains, and more.

### Emoji Reactions

Emoji reactions are available, compatible with Misskey and Pleroma.

### Quotes

Allows quotes that are reachable to the original post, not dead copies.

### Groups

Allows you to create and manage groups, discover groups, a timeline dedicated to groups, and post to groups. You can join a group from your existing Fediverse account.

### Posts expiry

Posts can be made private when they expire. People who have favorited, bookmarked, or emoji-reacted to your posts will still be able to see them.

## Deployment

**Tech stack:**

- **Ruby on Rails** powers the REST API and other web pages
- **React.js** and Redux are used for the dynamic parts of the interface
- **Node.js** powers the streaming API

**Requirements:**

- **PostgreSQL** 10+ (Note: Requires a newer version than Mastodon)
- **Redis** 4+
- **Ruby** 2.5+
- **Node.js** 12+

## Contributing

Fedibird is **free, open-source software** licensed under **AGPLv3**.

However, if you are not targeting Fedibird-specific features, please consider contributing to the upstream first; see Mastodon's [CONTRIBUTING.md](CONTRIBUTING.md). If you want to make an issue or pull request to Fedibird, please do so to the default branch of fedibird/mastodon.

## License

Copyright (C) 2018-2021 Takeshi Umeda  
based on code by Mastodon Copyright (C) 2016-2021 Eugen Rochko & other Mastodon contributors (see [AUTHORS.md](AUTHORS.md))

This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
